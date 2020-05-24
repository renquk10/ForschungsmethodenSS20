create table benchmarker.t_pkw_marken
(
    code    varchar(50),
    name    text,
    en_name text,
    de_desc text,
    de_link text,
    en_desc text,
    en_link text,
    de_syn  text,
    en_syn  text
);

alter table benchmarker.t_pkw_marken
    owner to postgres;

create table benchmarker.t_fahrzeuge
(
    code    varchar(50),
    name    text,
    en_name text,
    de_desc text,
    de_link text,
    en_desc text,
    en_link text,
    de_syn  text,
    en_syn  text
);

alter table benchmarker.t_fahrzeuge
    owner to postgres;

create table benchmarker.t_zeit_monatswerte
(
    code    varchar(50),
    name    text,
    en_name text,
    de_desc text,
    de_link text,
    en_desc text,
    en_link text,
    de_syn  text,
    en_syn  text
);

alter table benchmarker.t_zeit_monatswerte
    owner to postgres;

create table benchmarker.t_neuzulassungen
(
    pkw_marken        varchar(50),
    zeit_monatswerten varchar(50),
    fahrzeugen        varchar(50),
    neuzulassungen    integer
);

alter table benchmarker.t_neuzulassungen
    owner to postgres;

