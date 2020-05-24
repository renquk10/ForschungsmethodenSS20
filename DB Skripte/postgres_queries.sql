SELECT tf.name, tpm.name, tzm.name
FROM benchmarker.t_neuzulassungen nz
LEFT JOIN benchmarker.t_fahrzeuge tf ON nz.fahrzeugen = tf.code
LEFT JOIN benchmarker.t_pkw_marken tpm on tpm.code = nz.pkw_marken
LEFT JOIN benchmarker.t_zeit_monatswerte tzm on tzm.code = nz.zeit_monatswerten
where tzm.name LIKE 'Nilsson (S) <086495>';

SELECT tzm.name, sum(neuzulassungen), LAG (sum(neuzulassungen)) over (partition by SUBSTR(tzm.name, 0, position(' ' in tzm.name)-1) order by tzm.name)
FROM benchmarker.t_neuzulassungen nz
LEFT JOIN benchmarker.t_fahrzeuge tf ON nz.fahrzeugen = tf.code
LEFT JOIN benchmarker.t_pkw_marken tpm on tpm.code = nz.pkw_marken
LEFT JOIN benchmarker.t_zeit_monatswerte tzm on tzm.code = nz.zeit_monatswerten
where tzm.name is not null
GROUP BY tzm.NAME;