SELECT
	c_custkey,
	c_name,
	EXTRACT (MONTH FROM o_orderdate) AS _month,
	EXTRACT (QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT (YEAR FROM o_orderdate) AS _year,
	SUM(l_extendedprice - (1 * l_discount)) AS returnloss
FROM
	tpch1.lineitem JOIN tpch1.orders ON l_orderkey = o_orderkey
	JOIN tpch1.customer ON o_custkey = c_custkey
WHERE 
	l_returnflag = 'R'
	-- AND c_name = 'Customer#000129976'
	-- AND EXTRACT (QUARTER FROM o_orderdate) = 1
GROUP BY
	c_custkey,
	c_name,
	EXTRACT (MONTH FROM o_orderdate),
	EXTRACT (QUARTER FROM o_orderdate),
	EXTRACT (YEAR FROM o_orderdate);