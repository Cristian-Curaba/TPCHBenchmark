-- SELECT pg_size_pretty( pg_total_relation_size('tpch1.lineitem_orders') );
-- SELECT pg_size_pretty( pg_total_relation_size('tpch1.customer_location') );
-- SELECT pg_size_pretty( pg_total_relation_size('tpch1.supplier_location') );

SET search_path TO tpch10;

--QUERY 1:

--- Vanilla version:
EXPLAIN ANALYSE VERBOSE WITH lineitem_orders AS (
	SELECT 
		l_partkey, 
		l_suppkey, 
		o_orderdate, 
		o_custkey, 
		l_extendedprice, 
		l_discount
	FROM lineitem JOIN orders ON (l_orderkey = o_orderkey)
), customer_location AS (
	SELECT 
		c_custkey, 
		c_name, 
		n_nationkey AS c_nationkey, 
		n_name AS c_nationname, 
		r_regionkey AS c_regionkey, 
		r_name AS c_regionname 
	FROM customer 
		JOIN nation ON (c_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey)
), supplier_location AS (
	SELECT 
		s_suppkey, 
		s_name, 
		n_nationkey AS s_nationkey, 
		n_name AS s_nationname, 
		r_regionkey AS s_regionkey, 
		r_name AS s_regionname 
	FROM supplier 
		JOIN nation ON (s_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey)
), query1 AS (
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
	FROM lineitem_orders 
		JOIN part ON l_partkey = p_partkey
		JOIN supplier_location ON (s_suppkey = l_suppkey)
		JOIN customer_location ON (c_custkey = o_custkey)
	WHERE
		s_nationkey <> c_nationkey
		AND p_type = 'PROMO BURNISHED COPPER'
		AND s_nationname = 'UNITED STATES'
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

--- With Materialized views version:
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
	FROM lineitem_orders_mv 
		JOIN part ON l_partkey = p_partkey
		JOIN supplier_location_mv ON (s_suppkey = l_suppkey)
		JOIN customer_location_mv ON (c_custkey = o_custkey)
	WHERE
		s_nationkey <> c_nationkey
		AND p_type = 'PROMO BURNISHED COPPER'
		AND s_nationname = 'UNITED STATES'
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
	
--QUERY 2:

--- Vanilla version:
EXPLAIN ANALYSE VERBOSE WITH lineitem_orders AS (
	SELECT
		o_orderkey, 
		l_partkey, 
		l_suppkey, 
		o_orderdate, 
		o_custkey,
		l_commitdate,
		l_receiptdate
	FROM lineitem JOIN orders ON (l_orderkey = o_orderkey)
), customer_location AS (
	SELECT 
		c_custkey, 
		n_nationkey AS c_nationkey, 
		n_name AS c_nationname, 
		r_regionkey AS c_regionkey, 
		r_name AS c_regionname 
	FROM customer 
		JOIN nation ON (c_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey)
), query2 AS (
SELECT 
	EXTRACT(YEAR FROM o_orderdate) AS _year,
	EXTRACT(MONTH FROM o_orderdate) AS _month,
	c_regionname,
	c_nationname,
	COUNT(DISTINCT(o_orderkey)) AS orders_no
FROM lineitem_orders
	JOIN part ON l_partkey = p_partkey
	JOIN customer_location ON (c_custkey = o_custkey)
WHERE 
	l_receiptdate > l_commitdate
	AND EXTRACT(MONTH FROM o_orderdate) = 1
	AND p_type = 'PROMO BURNISHED COPPER'
GROUP BY
	_year,
	_month,
	c_regionkey,
	c_regionname,
	c_nationkey,
	c_nationname
)
SELECT * FROM query2;

--- With Materialized views version:
EXPLAIN ANALYSE VERBOSE WITH query2 AS (
SELECT 
	EXTRACT(YEAR FROM o_orderdate) AS _year,
	EXTRACT(MONTH FROM o_orderdate) AS _month,
	c_regionname,
	c_nationname,
	COUNT(DISTINCT(o_orderkey)) AS orders_no
FROM lineitem_orders_mv
	JOIN part ON l_partkey = p_partkey
	JOIN customer_location_mv ON (c_custkey = o_custkey)
WHERE 
	l_receiptdate > l_commitdate
	AND EXTRACT(MONTH FROM o_orderdate) = 1
	AND p_type = 'PROMO BURNISHED COPPER'
GROUP BY
	_year,
	_month,
	c_regionkey,
	c_regionname,
	c_nationkey,
	c_nationname
)
SELECT * FROM query2;

--QUERY 3:

--- Vanilla version:
EXPLAIN ANALYSE VERBOSE WITH lineitem_orders AS (
	SELECT 
		o_orderkey, 
		o_orderdate, 
		o_custkey, 
		l_extendedprice, 
		l_discount, 
		l_returnflag
	FROM lineitem JOIN orders ON (l_orderkey=o_orderkey)
),
query3 AS (
SELECT
	EXTRACT(YEAR FROM o_orderdate) AS _year,
	EXTRACT(QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT(MONTH FROM o_orderdate) AS _month,
	c_name,
	SUM(l_extendedprice*(1-l_discount)) AS returnloss
FROM
	lineitem_orders
	JOIN customer ON (o_custkey=c_custkey)
WHERE 
	l_returnflag='R'
	AND c_name='Customer#000129976'
	AND EXTRACT(QUARTER FROM o_orderdate) = 1
GROUP BY
	_year,
	_quarter,
	_month,
	c_custkey,
	c_name
)
SELECT * FROM query3;

--- With Materialized views version:
EXPLAIN ANALYSE VERBOSE WITH query3 AS (
SELECT
	EXTRACT (YEAR FROM o_orderdate) AS _year,
	EXTRACT (QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT (MONTH FROM o_orderdate) AS _month,
	c_name,
	SUM(l_extendedprice * (1 - l_discount)) AS returnloss
FROM
	lineitem_orders_mv
	JOIN customer ON o_custkey = c_custkey
WHERE 
	l_returnflag = 'R'
	AND c_name = 'Customer#000129976'
	AND EXTRACT (QUARTER FROM o_orderdate) = 1
GROUP BY
	_year,
	_quarter,
	_month,
	c_custkey,
	c_name
)
SELECT * FROM query3;


-- Materialized views definitions:

CREATE MATERIALIZED VIEW lineitem_orders_mv AS
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
	FROM lineitem JOIN orders ON (l_orderkey = o_orderkey);

CREATE MATERIALIZED VIEW customer_location_mv AS
	SELECT 
		c_custkey, 
		c_name, 
		n_nationkey AS c_nationkey, 
		n_name AS c_nationname, 
		r_regionkey AS c_regionkey, 
		r_name AS c_regionname 
	FROM customer 
		JOIN nation ON (c_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey);
		
--
CREATE MATERIALIZED VIEW supplier_location_mv AS
	SELECT 
		s_suppkey, 
		s_name, 
		n_nationkey AS s_nationkey, 
		n_name AS s_nationname, 
		r_regionkey AS s_regionkey, 
		r_name AS s_regionname 
	FROM supplier 
		JOIN nation ON (s_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey);
		

-- Index definitions

-- Indexes on relations (on common attributes between at least two relations):
CREATE INDEX IF NOT EXISTS lineitem_l_orderkey_idx
    ON lineitem USING btree
    (l_orderkey ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS lineitem_l_suppkey_idx
    ON lineitem USING btree
    (l_suppkey ASC NULLS LAST)
    TABLESPACE pg_default;
	
CREATE INDEX IF NOT EXISTS lineitem_l_partkey_idx
    ON lineitem USING btree
    (l_partkey ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS order_o_orderdate_idx
    ON orders USING btree
    (o_orderdate ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS order_o_custkey_idx
    ON orders USING btree
    (o_custkey ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS part_p_type_idx
	ON part USING btree
	(p_type ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS nation_n_name_idx
	ON nation USING btree
	(n_name ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS region_r_name_idx
	ON region USING btree
	(r_name ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS supplier_s_nationkey_idx
	ON supplier USING btree
	(s_nationkey ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS customer_c_nationkey_idx
	ON customer USING btree
	(c_nationkey ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS customer_c_name_idx
	ON customer USING btree
	(c_name ASC NULLS LAST)
	TABLESPACE pg_default;

--- Indexes on materialized views: (on common attributes between at least two materialized views):
CREATE INDEX IF NOT EXISTS lineitem_orders_o_orderkey_idx
    ON lineitem_orders_mv USING btree
    (o_orderkey ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS lineitem_orders_l_suppkey_idx
    ON lineitem_orders_mv USING btree
    (l_suppkey ASC NULLS LAST)
    TABLESPACE pg_default;
	
CREATE INDEX IF NOT EXISTS lineitem_orders_l_partkey_idx
    ON lineitem_orders_mv USING btree
    (l_partkey ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS lineitem_orders_o_orderdate_idx
    ON lineitem_orders_mv USING btree
    (o_orderdate ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS lineitem_orders_o_custkey_idx
    ON lineitem_orders_mv USING btree
    (o_custkey ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS supplier_location_s_nationkey_idx
	ON supplier_location_mv USING btree
	(s_nationkey ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS supplier_location_s_nationname_idx
	ON supplier_location_mv USING btree
	(s_nationname ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS supplier_location_s_regionkey_idx
	ON supplier_location_mv USING btree
	(s_regionkey ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS supplier_location_s_regionname_idx
	ON supplier_location_mv USING btree
	(s_regionname ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS customer_location_c_nationkey_idx
	ON customer_location_mv USING btree
	(c_nationkey ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS customer_location_c_nationname_idx
	ON customer_location_mv USING btree
	(c_nationname ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS customer_location_c_regionkey_idx
	ON customer_location_mv USING btree
	(c_regionkey ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS customer_location_c_regionname_idx
	ON customer_location_mv USING btree
	(c_regionname ASC NULLS LAST)
	TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS customer_location_c_name_idx
	ON customer_location_mv USING btree
	(c_name ASC NULLS LAST)
	TABLESPACE pg_default;


-- Vertical Fragmentation

--- Fragment definitions:

---- NATION: 
----- no fragmentation, the fragment used by the queries will have 3 columns and the other 1 column only.

---- REGION:
----- no fragmentation, the fragment used by the queries will have 2 columns and the other 1 column only.

---- CUSTOMER:
CREATE TABLE IF NOT EXISTS customer_frag_1
(
    c_custkey integer NOT NULL,
    c_name character varying(25) COLLATE pg_catalog."default" NOT NULL,
    c_nationkey integer NOT NULL,
    CONSTRAINT customer_frag_1_pkey PRIMARY KEY (c_custkey),
    CONSTRAINT customer_frag_1_fk1 FOREIGN KEY (c_nationkey)
        REFERENCES nation (n_nationkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) AS
SELECT
	c_custkey,
	c_name,
	c_nationkey
FROM customer;

CREATE TABLE IF NOT EXISTS customer_frag_2
(
	c_custkey integer NOT NULL,
    c_address character varying(40) COLLATE pg_catalog."default" NOT NULL,
    c_phone character(15) COLLATE pg_catalog."default" NOT NULL,
    c_acctbal numeric(15,2) NOT NULL,
    c_mktsegment character(10) COLLATE pg_catalog."default" NOT NULL,
    c_comment character varying(117) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT customer_frag_2_pkey PRIMARY KEY (c_custkey)
) AS
SELECT
	c_custkey,
	c_address,
	c_phone,
	c_acctbal,
	c_mktsegment,
	c_comment
FROM customer;

---- SUPPLIER:
CREATE TABLE IF NOT EXISTS supplier_frag_1
(
    s_suppkey integer NOT NULL,
    s_name character(25) COLLATE pg_catalog."default" NOT NULL,
    s_nationkey integer NOT NULL,
    CONSTRAINT supplier_frag_1_pkey PRIMARY KEY (s_suppkey),
    CONSTRAINT supplier_frag_1_fk1 FOREIGN KEY (s_nationkey)
        REFERENCES nation (n_nationkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) AS
SELECT
	s_suppkey,
	s_name,
	s_nationkey
FROM supplier;

CREATE TABLE IF NOT EXISTS supplier_frag_2
(
    s_suppkey integer NOT NULL,
    s_address character varying(40) COLLATE pg_catalog."default" NOT NULL,
    s_phone character(15) COLLATE pg_catalog."default" NOT NULL,
    s_acctbal numeric(15,2) NOT NULL,
    s_comment character varying(101) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT supplier_frag_2_pkey PRIMARY KEY (s_suppkey)
) AS
SELECT
	s_suppkey,
	s_address,
	s_phone,
	s_acctbal,
	s_comment
FROM supplier;

---- PARTSUPP: no fragmentation (table not used in queries)

---- PART:
CREATE TABLE IF NOT EXISTS part_frag_1
(
    p_partkey integer NOT NULL,
    p_type character varying(25) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT part_frag_1_pkey PRIMARY KEY (p_partkey)
) AS
SELECT
	p_partkey,
	p_type
FROM part;

CREATE TABLE IF NOT EXISTS part_frag_2
(
    p_partkey integer NOT NULL,
    p_name character varying(55) COLLATE pg_catalog."default" NOT NULL,
    p_mfgr character(25) COLLATE pg_catalog."default" NOT NULL,
    p_brand character(10) COLLATE pg_catalog."default" NOT NULL,
    p_size integer NOT NULL,
    p_container character(10) COLLATE pg_catalog."default" NOT NULL,
    p_retailprice numeric(15,2) NOT NULL,
    p_comment character varying(23) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT part_frag_2_pkey PRIMARY KEY (p_partkey)
) AS
SELECT 
	p_partkey,
	p_name,
	p_mfgr,
	p_brand,
	p_size,
	p_container,
	p_retailprice,
	p_comment
FROM part;

---- ORDERS:
CREATE TABLE IF NOT EXISTS orders_frag_1
(
    o_orderkey integer NOT NULL,
    o_custkey integer NOT NULL,
    o_orderdate date NOT NULL,
    CONSTRAINT orders_frag_1_pkey PRIMARY KEY (o_orderkey),
    CONSTRAINT orders_frag_1_fk1 FOREIGN KEY (o_custkey)
        REFERENCES customer (c_custkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) AS
SELECT
	o_orderkey,
	o_custkey,
	o_orderdate
FROM orders;

CREATE TABLE IF NOT EXISTS orders_frag_2
(
    o_orderkey integer NOT NULL,
    o_orderstatus character(1) COLLATE pg_catalog."default" NOT NULL,
    o_totalprice numeric(15,2) NOT NULL,
    o_orderpriority character(15) COLLATE pg_catalog."default" NOT NULL,
    o_clerk character(15) COLLATE pg_catalog."default" NOT NULL,
    o_shippriority integer NOT NULL,
    o_comment character varying(79) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT orders_frag_2_pkey PRIMARY KEY (o_orderkey)
) AS
SELECT
	o_orderkey,
	o_orderstatus,
	o_totalprice,
	o_orderpriority,
	o_clerk,
	o_shippriority,
	o_comment
FROM orders;

---- LINEITEM:
CREATE TABLE IF NOT EXISTS lineitem_frag_1
(
    l_orderkey integer NOT NULL,
    l_partkey integer NOT NULL,
    l_suppkey integer NOT NULL,
    l_linenumber integer NOT NULL,
    l_extendedprice numeric(15,2) NOT NULL,
    l_discount numeric(15,2) NOT NULL,
    l_returnflag character(1) COLLATE pg_catalog."default" NOT NULL,
    l_commitdate date NOT NULL,
    l_receiptdate date NOT NULL,
    CONSTRAINT lineitem_frag_1_pkey PRIMARY KEY (l_orderkey, l_linenumber),
    CONSTRAINT lineitem_frag_1_fk1 FOREIGN KEY (l_orderkey)
        REFERENCES orders (o_orderkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT lineitem_frag_1_fk2 FOREIGN KEY (l_partkey, l_suppkey)
        REFERENCES partsupp (ps_partkey, ps_suppkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) AS
SELECT
	l_orderkey,
	l_linenumber,
	l_partkey,
	l_suppkey,
	l_extendedprice,
	l_discount,
	l_returnflag,
	l_commitdate,
	l_receiptdate
FROM lineitem;

CREATE TABLE IF NOT EXISTS lineitem_frag_2
(
    l_orderkey integer NOT NULL,
    l_linenumber integer NOT NULL,
    l_quantity numeric(15,2) NOT NULL,
    l_tax numeric(15,2) NOT NULL,
    l_linestatus character(1) COLLATE pg_catalog."default" NOT NULL,
    l_shipdate date NOT NULL,
    l_shipinstruct character(25) COLLATE pg_catalog."default" NOT NULL,
    l_shipmode character(10) COLLATE pg_catalog."default" NOT NULL,
    l_comment character varying(44) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT lineitem_frag_2_pkey PRIMARY KEY (l_orderkey, l_linenumber),
    CONSTRAINT lineitem_frag_2_fk FOREIGN KEY (l_orderkey)
        REFERENCES orders (o_orderkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) AS
SELECT
	l_orderkey,
	l_linenumber,
	l_quantity,
	l_tax,
	l_linestatus,
	l_shipdate,
	l_shipinstruct,
	l_shipmode,
	l_comment
FROM lineitem;

---- WARNING: be sure to have defined all the previous fragments before doing the following steps
---- Delete the original tables
DROP TABLE customer;
DROP TABLE supplier;
DROP TABLE part;
DROP TABLE orders;
DROP TABLE lineitem;

---- Queries on fragments:
---- Q1:
EXPLAIN ANALYSE VERBOSE WITH lineitem_orders AS (
	SELECT 
		l_partkey, 
		l_suppkey, 
		o_orderdate, 
		o_custkey, 
		l_extendedprice, 
		l_discount
	FROM lineitem_frag_1 JOIN orders_frag_1 ON (l_orderkey = o_orderkey)
), customer_location AS (
	SELECT 
		c_custkey, 
		c_name, 
		n_nationkey AS c_nationkey, 
		n_name AS c_nationname, 
		r_regionkey AS c_regionkey, 
		r_name AS c_regionname 
	FROM customer_frag_1 
		JOIN nation ON (c_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey)
), supplier_location AS (
	SELECT 
		s_suppkey, 
		s_name, 
		n_nationkey AS s_nationkey, 
		n_name AS s_nationname, 
		r_regionkey AS s_regionkey, 
		r_name AS s_regionname 
	FROM supplier_frag_1
		JOIN nation ON (s_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey)
), query1 AS (
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
	FROM lineitem_orders 
		JOIN part_frag_1 ON l_partkey = p_partkey
		JOIN supplier_location ON (s_suppkey = l_suppkey)
		JOIN customer_location ON (c_custkey = o_custkey)
	WHERE
		s_nationkey <> c_nationkey
		AND p_type = 'PROMO BURNISHED COPPER'
		AND s_nationname = 'UNITED STATES'
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

---- Q2:
EXPLAIN ANALYSE VERBOSE WITH lineitem_orders AS (
	SELECT
		o_orderkey, 
		l_partkey, 
		l_suppkey, 
		o_orderdate, 
		o_custkey,
		l_commitdate,
		l_receiptdate
	FROM lineitem_frag_1 JOIN orders_frag_1 ON (l_orderkey = o_orderkey)
), customer_location AS (
	SELECT 
		c_custkey, 
		n_nationkey AS c_nationkey, 
		n_name AS c_nationname, 
		r_regionkey AS c_regionkey, 
		r_name AS c_regionname 
	FROM customer_frag_1 
		JOIN nation ON (c_nationkey = n_nationkey)
		JOIN region ON (n_regionkey = r_regionkey)
), query2 AS (
SELECT 
	EXTRACT(YEAR FROM o_orderdate) AS _year,
	EXTRACT(MONTH FROM o_orderdate) AS _month,
	c_regionname,
	c_nationname,
	COUNT(DISTINCT(o_orderkey)) AS orders_no
FROM lineitem_orders
	JOIN part_frag_1 ON l_partkey = p_partkey
	JOIN customer_location ON (c_custkey = o_custkey)
WHERE 
	l_receiptdate > l_commitdate
	AND EXTRACT(MONTH FROM o_orderdate) = 1
	AND p_type = 'PROMO BURNISHED COPPER'
GROUP BY
	_year,
	_month,
	c_regionkey,
	c_regionname,
	c_nationkey,
	c_nationname
)
SELECT * FROM query2;

---- Q3:
EXPLAIN ANALYSE VERBOSE WITH lineitem_orders AS (
	SELECT 
		o_orderkey, 
		o_orderdate, 
		o_custkey, 
		l_extendedprice, 
		l_discount, 
		l_returnflag
	FROM lineitem_frag_1 JOIN orders_frag_1 ON (l_orderkey=o_orderkey)
),
query3 AS (
SELECT
	EXTRACT(YEAR FROM o_orderdate) AS _year,
	EXTRACT(QUARTER FROM o_orderdate) AS _quarter,
	EXTRACT(MONTH FROM o_orderdate) AS _month,
	c_name,
	SUM(l_extendedprice*(1-l_discount)) AS returnloss
FROM
	lineitem_orders
	JOIN customer_frag_1 ON (o_custkey=c_custkey)
WHERE 
	l_returnflag='R'
	AND c_name='Customer#000129976'
	AND EXTRACT(QUARTER FROM o_orderdate) = 1
GROUP BY
	_year,
	_quarter,
	_month,
	c_custkey,
	c_name
)
SELECT * FROM query3;