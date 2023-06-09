SELECT 
	EXTRACT(MONTH FROM o_orderdate) AS _month,
	EXTRACT(YEAR FROM o_orderdate) AS _year,
	c_nationkey,
	n_regionkey,
	COUNT(DISTINCT(l_orderkey)) AS orders_no
FROM 
	tpch1.lineitem JOIN tpch1.orders ON l_orderkey = o_orderkey
	JOIN tpch1.customer ON o_custkey = c_custkey
	JOIN tpch1.nation ON c_nationkey = n_nationkey
	JOIN tpch1.part ON l_partkey = p_partkey
WHERE 
	l_receiptdate > l_commitdate
	-- AND _month = 1
	-- AND p_type = 'PROMO BURNISHED COPPER'
GROUP BY
	_month,
	_year,
	c_nationkey,
	n_regionkey;