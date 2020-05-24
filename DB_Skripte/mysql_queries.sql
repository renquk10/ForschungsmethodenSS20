SELECT tf.name, tpm.name, tzm.name
FROM t_neuzulassungen nz
LEFT JOIN t_fahrzeuge tf ON nz.fahrzeugen = tf.code
LEFT JOIN t_pkw_marken tpm on tpm.code = nz.pkw_marken
LEFT JOIN t_zeit_monatswerte tzm on tzm.code = nz.zeit_monatswerten
where tzm.name LIKE 'Nilsson (S) <086495>';

SELECT tzm.name, sum(neuzulassungen), LAG (sum(neuzulassungen)) over (partition by SUBSTR(tzm.name, 0, INSTR(tzm.name, ' ')-1) order by tzm.name)
FROM t_neuzulassungen nz
LEFT JOIN t_fahrzeuge tf ON nz.fahrzeugen = tf.code
LEFT JOIN t_pkw_marken tpm on tpm.code = nz.pkw_marken
LEFT JOIN t_zeit_monatswerte tzm on tzm.code = nz.zeit_monatswerten
where tzm.name is not null
GROUP BY tzm.NAME;