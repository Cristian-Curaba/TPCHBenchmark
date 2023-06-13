-- SELECT pg_size_pretty( pg_total_relation_size('tpch1.lineitem_orders') );
-- SELECT pg_size_pretty( pg_total_relation_size('tpch1.customer_location') );
-- SELECT pg_size_pretty( pg_total_relation_size('tpch1.supplier_location') );

--
CREATE MATERIALIZED VIEW tpch1.lineitem_orders AS
	SELECT 
		o_orderkey, 
		l_partkey, 
		l_suppkey, 
		o_orderdate, 
		o_custkey, 
		l_extendedprice, 
		l_discount, 
		l_returnflag,
		l_commitdate,
		l_receiptdate
	FROM tpch1.lineitem JOIN tpch1.orders ON (l_orderkey = o_orderkey);
	
-- 
CREATE MATERIALIZED VIEW tpch1.customer_location AS
	SELECT 
		c_custkey, 
		c_name, 
		n_nationkey AS c_nationkey, 
		n_name AS c_nationname, 
		r_regionkey AS c_regionkey, 
		r_name AS c_regionname 
	FROM tpch1.customer 
		JOIN tpch1.nation ON (c_nationkey = n_nationkey)
		JOIN tpch1.region ON (n_regionkey = r_regionkey);
		
--
CREATE MATERIALIZED VIEW tpch1.supplier_location AS
	SELECT 
		s_suppkey, 
		s_name, 
		n_nationkey AS s_nationkey, 
		n_name AS s_nationname, 
		r_regionkey AS s_regionkey, 
		r_name AS s_regionname 
	FROM tpch1.supplier 
		JOIN tpch1.nation ON (s_nationkey = n_nationkey)
		JOIN tpch1.region ON (n_regionkey = r_regionkey);
		
--Query1:
EXPLAIN ANALYSE VERBOSE WITH query1 AS (
SELECT
	EXTRACT (YEAR FROM o_orderdate) AS _year,
	EXTRACT (QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT (MONTH FROM o_orderdate) AS _month,
	c_regionname,
	c_nationname,
	c_name,
	s_regionname,
	s_nationname,
	s_name,
	p_type,
	SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM tpch1.lineitem_orders 
	JOIN tpch1.part ON l_partkey = p_partkey
	JOIN tpch1.supplier_location ON (s_suppkey = l_suppkey)
	JOIN tpch1.customer_location ON (c_custkey = o_custkey)
WHERE s_nationkey <> c_nationkey
GROUP BY
	_year,
	_quarter,
	_month,
	c_regionkey,
	c_regionname,
	c_nationkey,
	c_nationname,
	c_custkey,
	c_name,
	s_regionkey,
	s_regionname,
	s_nationkey,
	s_nationname,
	s_suppkey,
	s_name,
	p_type
) 
SELECT * FROM query1;
	
--Query 2:
EXPLAIN ANALYSE WITH query2 AS (
SELECT 
	EXTRACT(YEAR FROM o_orderdate) AS _year,
	EXTRACT(MONTH FROM o_orderdate) AS _month,
	c_regionname,
	c_nationname,
	COUNT(DISTINCT(o_orderkey)) AS orders_no
FROM tpch1.lineitem_orders
	JOIN tpch1.part ON l_partkey = p_partkey
	JOIN tpch1.customer_location ON (c_custkey = o_custkey)
WHERE 
	l_receiptdate > l_commitdate
	-- AND _month = 1
	-- AND p_type = 'PROMO BURNISHED COPPER'
GROUP BY
	_year,
	_month,
	c_regionkey,
	c_regionname,
	c_nationkey,
	c_nationname
)
SELECT * FROM query2;

--Query 3:
EXPLAIN ANALYSE VERBOSE WITH query3 AS (
SELECT
	EXTRACT (YEAR FROM o_orderdate) AS _year,
	EXTRACT (QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT (MONTH FROM o_orderdate) AS _month,
	c_name,
	SUM(l_extendedprice * (1 - l_discount)) AS returnloss
FROM
	tpch1.lineitem_orders
	JOIN tpch1.customer ON o_custkey = c_custkey
WHERE 
	l_returnflag = 'R'
	-- AND c_name = 'Customer#000129976'
	-- AND EXTRACT (QUARTER FROM o_orderdate) = 1
GROUP BY
	_year,
	_quarter,
	_month,
	c_custkey,
	c_name
)
SELECT * FROM query3;
