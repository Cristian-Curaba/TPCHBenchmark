CREATE MATERIALIZED VIEW tpch1.lineitem_orders(orderkey, custkey, suppkey, extendedprice, discount) AS
	SELECT lineitem.l_orderkey, orders.o_custkey, lineitem.l_suppkey, lineitem.l_extendedprice, lineitem.l_discount
	FROM tpch1.lineitem JOIN tpch1.orders ON lineitem.l_orderkey = orders.o_orderkey;

CREATE MATERIALIZED VIEW tpch1.supplier_nk(suppkey, s_nationkey) AS
	SELECT tpch1.supplier.s_suppkey, tpch1.supplier.s_nationkey
	FROM tpch1.lineitem_orders JOIN tpch1.supplier ON lineitem_orders.suppkey = supplier.s_suppkey;

CREATE MATERIALIZED VIEW tpch1.customer_nk(custkey, c_nationkey) AS
	SELECT tpch1.customer.c_custkey, tpch1.customer.c_nationkey
	FROM tpch1.lineitem_orders JOIN tpch1.customer ON lineitem_orders.custkey = customer.c_custkey;

WITH supp_cust_nation AS (
	SELECT suppkey, custkey, s_nationkey AS nationkey
	FROM tpch1.supplier_nk JOIN tpch1.customer_nk ON s_nationkey = c_nationkey
)

SELECT lineitem_orders.extendedprice * (1 - lineitem_orders.discount) AS revenue
FROM tpch1.lineitem_orders NATURAL JOIN supp_cust_nation;


