-- Export/import revenue value.

/*
Aggregation of the export/import of revenue of lineitems between two nations (E,I) where E is the nation of the lineitem
supplier and I the nations of the lineitem customer. The revenue is obtained by l_extendedprice * (1 - l_discount) of the considered lineitems
*/

-- Roll-up: month - type - nation

WITH revenue_suppliers_nations AS (
	SELECT
		EXTRACT (MONTH FROM o.o_orderdate) AS _month,
		pa.p_type AS _type,
		s.s_nationkey AS nationkey,
		SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue_suppliers
	FROM tpch1.orders AS o
		JOIN tpch1.lineitem AS l ON o.o_orderkey = l.l_orderkey
		JOIN tpch1.supplier AS s ON l.l_suppkey = s.s_suppkey
		JOIN tpch1.nation AS n ON s.s_nationkey = n.n_nationkey
		JOIN tpch1.part AS pa ON l.l_partkey = pa.p_partkey
	GROUP BY (_month, _type, nationkey)
), revenue_customers_nations AS (
	SELECT
		EXTRACT (MONTH FROM o.o_orderdate) AS _month,
		pa.p_type AS _type,
		cu.c_nationkey AS nationkey,
		SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue_customer
	FROM tpch1.orders AS o 
		JOIN tpch1.lineitem AS l ON o.o_orderkey = l.l_orderkey
		JOIN tpch1.customer AS cu ON o.o_custkey = cu.c_custkey
		JOIN tpch1.nation AS n ON cu.c_nationkey = n.n_nationkey
		JOIN tpch1.part AS pa ON l.l_partkey = pa.p_partkey
	GROUP BY (_month, _type, nationkey)
)
	
SELECT 
	rsn.nationkey AS E,
	rcn.nationkey AS I,
	rsn._month AS _month,
	rsn._type AS _type,
	(rsn.revenue_suppliers/rcn.revenue_customer) AS E_I
FROM revenue_suppliers_nations AS rsn JOIN revenue_customers_nations AS rcn 
	ON rsn._month = rcn._month AND rsn._type = rcn._type AND rsn.nationkey <> rcn.nationkey; -- Assuming E != I