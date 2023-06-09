-- Export/import revenue value.

/*
Aggregation of the export/import of revenue of lineitems between two nations (E,I) where E is the nation of the lineitem
supplier and I the nations of the lineitem customer. The revenue is obtained by l_extendedprice * (1 - l_discount) of the considered lineitems
*/

CREATE OR REPLACE VIEW tpch1.supplier_regions AS
	SELECT s_suppkey AS sr_suppkey, s_nationkey AS sr_nationkey, n_name AS sr_name, n_regionkey AS sr_regionkey
	FROM tpch1.supplier JOIN tpch1.nation ON s_nationkey = n_nationkey;
	
CREATE OR REPLACE VIEW tpch1.customer_regions AS
	SELECT c_custkey AS cr_custkey, c_nationkey AS cr_nationkey, n_name AS cr_name, n_regionkey AS cr_regionkey
	FROM tpch1.customer JOIN tpch1.nation ON c_nationkey = n_nationkey;

SELECT
	EXTRACT (YEAR FROM o_orderdate) AS _year,
	EXTRACT (QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT (MONTH FROM o_orderdate) AS _month,
	cr_custkey,
	cr_nationkey,
	cr_name,
	cr_regionkey,
	sr_suppkey,
	sr_nationkey,
	sr_name,
	sr_regionkey,
	p_type,
	SUM(l_extendedprice * (1 - l_discount))
FROM
	tpch1.lineitem JOIN tpch1.orders ON l_orderkey = o_orderkey
	JOIN tpch1.customer_regions ON o_custkey = cr_custkey
	JOIN tpch1.supplier_regions ON l_suppkey = sr_suppkey
	JOIN tpch1.part ON l_partkey = p_partkey
WHERE sr_nationkey <> cr_nationkey
GROUP BY
	_year,
	_quarter,
	_month,
	cr_custkey,
	cr_nationkey,
	cr_name,
	cr_regionkey,
	sr_suppkey,
	sr_nationkey,
	sr_name,
	sr_regionkey,
	p_type;
