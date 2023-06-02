-- Rappresentare nella relazione con grafici

-- Table Size
SELECT pg_size_pretty( pg_total_relation_size('tpch10.orders') );

-- Number of rows
SELECT count(*)
FROM tpch10.orders;

-- Distinct values for each attribute
SELECT DISTINCT o_orderpriority
FROM tpch10.orders;

-- Min, Max for each meaningful attribute
SELECT MIN(o_totalprice) AS min, MAX(o_totalprice) as max
FROM tpch10.orders;