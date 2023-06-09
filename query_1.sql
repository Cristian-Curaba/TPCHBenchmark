CREATE OR REPLACE VIEW tpch1.suppliers_customers_same AS
	SELECT 
		s_suppkey AS scs_suppkey,
		c_custkey AS scs_custkey, 
		n_nationkey AS scs_nationkey,
		n_name AS scs_nationname,
		n_regionkey AS scs_regionkey
	FROM
		tpch1.supplier JOIN tpch1.nation ON s_nationkey = n_nationkey
		JOIN tpch1.customer ON c_nationkey = n_nationkey
	WHERE s_nationkey = c_nationkey;

SELECT
	EXTRACT (YEAR FROM o_orderdate) AS _year,
	EXTRACT (QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT (MONTH FROM o_orderdate) AS _month,
	p_type,
	scs_nationkey,
	scs_nationname,
	scs_regionkey,
	r_name, 
	SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
	tpch1.lineitem JOIN tpch1.orders ON l_orderkey = o_orderkey
	JOIN tpch1.suppliers_customers_same ON scs_suppkey = l_suppkey AND scs_custkey = o_custkey
	JOIN tpch1.part ON l_partkey = p_partkey
	JOIN tpch1.region ON scs_regionkey = r_regionkey
GROUP BY 
	_year,
	_quarter,
	_month,
	p_type,
	scs_nationkey,
	scs_nationname,
	scs_regionkey,
	r_name;