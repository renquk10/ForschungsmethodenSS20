##
# docker run --name pkw-oracle -v C:\dockershare:/data -p 1521:1521 -p 5500:5500 -d store/oracle/database-enterprise:12.2.0.1
# docker run --name pkw-mysql -e MYSQL_ROOT_PASSWORD=mysecretpassword -v C:\dockershare:/data -p 3306:3306 -d mysql:latest
# docker run --name pkw-postgres -e POSTGRES_PASSWORD=mysecretpassword -v C:\dockershare:/data -p 5432:5432 -d postgres
##
### DB Parameter

## Oracle   
# sqlplus sys/Oradoc_db1@ORCLCDB as sysdba
# sqlplus.exe  benchmarker/fmss2020@localhost/ORCLCDB.localdomain

# to be executes on oracle vm prior to scripts
# docker exec -it pkw-oracle bash
# sqlplus
# connect sys as sysdba 
# password Oradoc_db1
#  alter session set "_ORACLE_SCRIPT" = true;
# create user benchmarker identified by fmss2020;
# GRANT ALL PRIVILEGES TO benchmarker;
# exit

############################################
#### ENVIRONMENT CONFIGURATION #############
############################################


$ORA_USER        = 'benchmarker'
$ORA_PASS        = 'fmss2020'
$ORA_HOST        = 'localhost'
$ORA_PORT        = '1521'
$ORA_DB          =  'ORCLCDB.localdomain'
$ORA_CLIENT_PATH = 'C:\Users\NFLR\OneDrive\Documents\Uni\Forschungsmethoden\DB scripts\instantclient_19_6\'
$ORA_CLIENT      = 'sqlplus'
$ORA_ARGS        = "$ORA_USER`/$ORA_PASS`@$ORA_HOST`/$ORA_DB"

## MYSql
# mysqlsh.exe -h localhost -u root -pmysecretpassword --database=benchmarker
$MS_USER = 'root'
$MS_PASS = 'mysecretpassword'
$MS_HOST = 'localhost'
$MS_PORT = '3306'
$MS_DB =  'benchmarker'
$MS_CLIENT_PATH = 'C:\Program Files\MySQL\MySQL Shell 8.0\bin'
$MS_CLIENT = 'mysqlsh'
$MS_ARGS = ""


##POSTGRES
$PG_USER = 'postgres'
$PG_PASS = 'mysecretpassword'
$PG_HOST = 'localhost'
$PG_PORT = '5432'
$PG_DB =  'postgres'
$PG_CLIENT_PATH = 'C:\Program Files\PostgreSQL\12\bin\'
$PG_CLIENT = 'psql'
$PG_ARGS = "--dbname=$PG_DB --username=$PG_USER"
$env:PGPASSWORD=$PG_PASS
# psql --dbname=postgres --username=postgres --database=benchmarker



 
$env:Path += ";$ORA_CLIENT_PATH" 
#$env:Path += ";$MS_CLIENT_PATH" # done by mysql installer
$env:Path += ";$PG_CLIENT_PATH" 

############################################
#### Test Configuration 
############################################

$no_executions = 200
$throttle = 50
$sample_count=10

############################################
### Helper Functions to start queries on the different systems
############################################

$whereclauses = Get-Content whereclause.csv

function ora_timespan {
    param ([string] $ora_time) 

    $hrs = [System.Convert]::ToDecimal($ora_time.Split(":")[0])
    $min = [System.Convert]::ToDecimal($ora_time.Split(":")[1])
    $sec = [System.Convert]::ToDecimal($ora_time.Split(":")[2],[cultureinfo]::GetCultureInfo('en_US'))

    return $hrs*3600 + $min*60 + $sec

}


function ora_run {
  param ([string]$sqlfilename, 
		[string]$wc)
  
  $ex_time = & $ORA_CLIENT "$ORA_USER`/$ORA_PASS`@$ORA_HOST`/$ORA_DB" "`@$sqlfilename" ""$wc"" |
  Where-Object { $_ -match 'Elapsed'}[0] |
  foreach-object {$_.Split(' ')[1]}

  return @{$sqlfilename= ora_timespan($ex_time)}
  
 }

function pg_run {
  param ([string]$sqlfilename, 
		[string]$wc)
  
  $ex_time = & "$PG_CLIENT" "--username=$PG_USER" "--dbname=$PG_DB" "-vquoted=""$wc""" "--file=$sqlfilename"  | 
  Where-Object { $_ -match 'Time:'}[0] |
  foreach-object {$_.Split(' ')[1]}

  $ex_time = [System.Convert]::ToDecimal($ex_time,[cultureinfo]::GetCultureInfo('de_DE'))
  return @{$sqlfilename= $ex_time/1000}
  
 }


function ms_run {
  param ([string]$sqlfilename, 
		[string]$wc)

  
  $WarningPreference = 'SilentlyContinue'
  
  $ex_time = & "$MS_CLIENT" "--json=pretty" "--host=localhost" "--user=$MS_USER" "--database=benchmarker" "--file=$sqlfilename"  | 
  ConvertFrom-Json

  $WarningPreference = 'Continue'

  $ex_time = $ex_time.executionTime | ForEach-Object{$_.Split(" ")[0]}
  $ex_time = [System.Convert]::ToDecimal($ex_time,[cultureinfo]::GetCultureInfo('en_US'))
  return @{$sqlfilename= $ex_time}
  
 }


$ora_results = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$pg_results = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$ms_results = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

####################################################
##### Simple Fast Queries ##########################
####################################################


for ($i=1;$i -le $sample_count; $i++) {
   
	# $val = ora_run("ora_simple.sql", $whereclauses[$i])
    # $ora_results.Add($val)
	
	$ex_time = & $ORA_CLIENT "$ORA_USER`/$ORA_PASS`@$ORA_HOST`/$ORA_DB" "`@ora_simple.sql" ""$whereclauses[$i]"" |
  Where-Object { $_ -match 'Elapsed'}[0] |
  foreach-object {$_.Split(' ')[1]}

  $ora_results.Add(@{"ora_simple.sql"= ora_timespan($ex_time)})
}


for ($i=1;$i -le $sample_count; $i++) {
    $ex_time = & "$PG_CLIENT" "--username=$PG_USER" "--dbname=$PG_DB" "-vquoted=""$whereclauses[$i]""" "--file=pg_simple.sql"  | 
  Where-Object { $_ -match 'Time:'}[0] |
  foreach-object {$_.Split(' ')[1]}

  $ex_time = [System.Convert]::ToDecimal($ex_time,[cultureinfo]::GetCultureInfo('de_DE'))
	$val = @{"pg_simple.sql"= $ex_time/1000}
    $pg_results.Add($val)
}


for ($i=1;$i -le $sample_count; $i++) {
	$ms_query = "SELECT tf.name, tpm.name, tzm.name FROM t_neuzulassungen nz LEFT JOIN t_fahrzeuge tf ON nz.fahrzeugen = tf.code LEFT JOIN t_pkw_marken tpm on tpm.code = nz.pkw_marken LEFT JOIN t_zeit_monatswerte tzm on tzm.code = nz.zeit_monatswerten where tpm.name LIKE '" + $whereclauses[$i] + "';"

    $WarningPreference = 'SilentlyContinue'
  
   $ex_time = & "$MS_CLIENT" "--json=pretty" "--sql" "--host=localhost" "--user=$MS_USER" "--database=benchmarker" "-e""$ms_query"""  
   $ex_time = $ex_time | ConvertFrom-Json

  $WarningPreference = 'Continue'

  $ex_time = $ex_time.executionTime | ForEach-Object{$_.Split(" ")[0]}
  $ex_time = [System.Convert]::ToDecimal($ex_time,[cultureinfo]::GetCultureInfo('en_US'))
  $val =  @{"ms_simple_query.sql"= $ex_time}
	#$val = ms_run("ms_simple.sql", $whereclauses[$i])
    $ms_results.Add($val)
}



###################################################
#### CONCURRENT QUERIES ###########################
###################################################

##Oracle 

# $ora_results2 = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$ora_run_def = $function:ora_run.ToString()
$ora_timespan_def = $function:ora_timespan.ToString()
$ms_run_def = $function:ms_run.ToString()
$pg_run_def = $function:pg_run.ToString()


1..$no_executions | ForEach-Object -Parallel {

    $ora_results = $using:ora_results
	
	
	$ORA_USER         =$using:ORA_USER       
	$ORA_PASS         =$using:ORA_PASS       
	$ORA_HOST         =$using:ORA_HOST       
	$ORA_PORT         =$using:ORA_PORT       
	$ORA_DB           =$using:ORA_DB         
	$ORA_CLIENT_PATH  =$using:ORA_CLIENT_PATH
	$ORA_CLIENT       =$using:ORA_CLIENT     
	$ORA_ARGS         =$using:ORA_ARGS     
	$whereclauses 	  =$using:whereclauses
	$function:ora_run = $using:ora_run_def
	$function:ora_timespan = $using:ora_timespan_def
	$x = get-random -Minimum 0 -Maximum 23
    $ex_time = & $ORA_CLIENT "$ORA_USER`/$ORA_PASS`@$ORA_HOST`/$ORA_DB" "`@ora_concurrent.sql" ""$whereclauses[$x]"" |
  Where-Object { $_ -match 'Elapsed'}[0] |
  foreach-object {$_.Split(' ')[1]}

  $ora_results.Add(@{"ora_concurrent.sql"= ora_timespan($ex_time)})
  
	#$val = ora_run("ora_concurrent.sql", $whereclauses[1])
    #$ora_results.Add($val)
	    
} -ThrottleLimit $throttle



1..$no_executions | ForEach-Object -Parallel {

    $MS_results = $using:MS_results
	
	$MS_USER         =$using:MS_USER       
	$MS_PASS         =$using:MS_PASS       
	$MS_HOST         =$using:MS_HOST       
	$MS_PORT         =$using:MS_PORT       
	$MS_DB           =$using:MS_DB         
	$MS_CLIENT_PATH  =$using:MS_CLIENT_PATH
	$MS_CLIENT       =$using:MS_CLIENT     
	$MS_ARGS         =$using:MS_ARGS       
	$function:MS_run = $using:MS_run_def
	$whereclauses 	  =$using:whereclauses

    $x = get-random -Minimum 0 -Maximum 23
	#$val = MS_run("MS_concurrent.sql", $whereclauses[$x])
    #$MS_results.Add($val)
	
	
	$ms_query = "SELECT tf.name, tpm.name, tzm.name FROM t_neuzulassungen nz LEFT JOIN t_fahrzeuge tf ON nz.fahrzeugen = tf.code LEFT JOIN t_pkw_marken tpm on tpm.code = nz.pkw_marken LEFT JOIN t_zeit_monatswerte tzm on tzm.code = nz.zeit_monatswerten where tpm.name LIKE '" + $whereclauses[$x] + "';"

    $WarningPreference = 'SilentlyContinue'
  
   $ex_time = & "$MS_CLIENT" "--json=pretty" "--sql" "--host=localhost" "--user=$MS_USER" "--database=benchmarker" "-e""$ms_query"""  
   $ex_time = $ex_time | ConvertFrom-Json

  $WarningPreference = 'Continue'

  $ex_time = $ex_time.executionTime | ForEach-Object{$_.Split(" ")[0]}
  $ex_time = [System.Convert]::ToDecimal($ex_time,[cultureinfo]::GetCultureInfo('en_US'))
  $val =  @{"ms_concurrent.sql"= $ex_time}
	#$val = ms_run("ms_simple.sql", $whereclauses[$i])
    $ms_results.Add($val)
	
    
} -ThrottleLimit $throttle


1..$no_executions | ForEach-Object -Parallel {

    $PG_results = $using:PG_results
	
	$PG_USER         =$using:PG_USER       
	$PG_PASS         =$using:PG_PASS       
	$PG_HOST         =$using:PG_HOST       
	$PG_PORT         =$using:PG_PORT       
	$PG_DB           =$using:PG_DB         
	$PG_CLIENT_PATH  =$using:PG_CLIENT_PATH
	$PG_CLIENT       =$using:PG_CLIENT     
	$PG_ARGS         =$using:PG_ARGS       
	$function:PG_run = $using:PG_run_def
	$whereclauses 	  =$using:whereclauses
	
    $x = get-random -Minimum 0 -Maximum 23
	#$val = PG_run("PG_concurrent.sql", $whereclauses[$x])
    #$PG_results.Add($val)
	
	$ex_time = & "$PG_CLIENT" "--username=$PG_USER" "--dbname=$PG_DB" "-vquoted=""$whereclauses[$x]""" "--file=pg_simple.sql"  | 
  Where-Object { $_ -match 'Time:'}[0] |
  foreach-object {$_.Split(' ')[1]}

  $ex_time = [System.Convert]::ToDecimal($ex_time,[cultureinfo]::GetCultureInfo('de_DE'))
	$val = @{"pg_concurrent.sql"= $ex_time/1000}
    $pg_results.Add($val)
	
} -ThrottleLimit $throttle



##########################################################
###  ANALYTIC QUERIES ####################################
##########################################################


for ($i=1;$i -le $sample_count; $i++) {
   
	$val = ora_run ( "ora_analytic.sql") 
    $ora_results.Add($val)
}


for ($i=1;$i -le $sample_count; $i++) {
   
   $val = pg_run("pg_analytic.sql")
    $pg_results.Add($val)
}


for ($i=1;$i -le $sample_count; $i++) {
	$val = ms_run("ms_analytic.sql")
    $ms_results.Add($val)
}




$ora_results > ora_results.csv
$pg_results  > pg_results.csv
$ms_results  > ms_results.csv