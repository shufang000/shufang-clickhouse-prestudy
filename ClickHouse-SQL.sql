CLickHouse SQL样例

`SELECT`
	SELECT [DISTINCT] expr_list
    [FROM [db.]table | (subquery) | table_function] [FINAL]
    [SAMPLE sample_coeff]
    [ARRAY JOIN ...]
    [GLOBAL] ANY|ALL INNER|LEFT JOIN (subquery)|table USING columns_list
    [PREWHERE expr]
    [WHERE expr]
    [GROUP BY expr_list] [WITH TOTALS]
    [HAVING expr]
    [ORDER BY expr_list]
    [LIMIT [n, ]m]
    [UNION ALL ...]
    [INTO OUTFILE filename]
    [FORMAT format]
    [LIMIT n BY columns]

    `FROM子句`
    -- 如果一个SQL没有FROM子句，就相当于select expr from dual;

    `SAMPLE子句`
    SELECT
    Title,
    count() * 10 AS PageViews
	FROM hits_distributed
	SAMPLE 0.1
	WHERE
	    CounterID = 34
	    AND toDate(EventDate) >= toDate('2013-01-29')
	    AND toDate(EventDate) <= toDate('2013-02-04')
	    AND NOT DontCountHits
	    AND NOT Refresh
	    AND Title != ''
	GROUP BY Title
	ORDER BY PageViews DESC LIMIT 1000

	`ARRAY JOIN 子句`
	:) CREATE TABLE arrays_test (s String, arr Array(UInt8)) ENGINE = Memory

CREATE TABLE arrays_test
(
    s String,
    arr Array(UInt8)
) ENGINE = Memory

Ok.

0 rows in set. Elapsed: 0.001 sec.

:) INSERT INTO arrays_test VALUES ('Hello', [1,2]), ('World', [3,4,5]), ('Goodbye', [])

INSERT INTO arrays_test VALUES

Ok.

3 rows in set. Elapsed: 0.001 sec.

:) SELECT * FROM arrays_test

SELECT *
FROM arrays_test

┌─s───────┬─arr─────┐
│ Hello   │ [1,2]   │
│ World   │ [3,4,5] │
│ Goodbye │ []      │
└─────────┴─────────┘

3 rows in set. Elapsed: 0.001 sec.

:) SELECT s, arr FROM arrays_test ARRAY JOIN arr

SELECT s, arr
FROM arrays_test
ARRAY JOIN arr

┌─s─────┬─arr─┐
│ Hello │   1 │
│ Hello │   2 │
│ World │   3 │
│ World │   4 │
│ World │   5 │
└───────┴─────┘

5 rows in set. Elapsed: 0.001 sec.

-- ARRAY JOIN子句可以起别名，并放进select中
-- 除了MYSQL引擎，基本所有引擎都是支持NULLABLE的

	`JOIN子句`
	SELECT <expr_list>
	FROM <left_subquery>
	[GLOBAL] [ANY|ALL] INNER|LEFT|RIGHT|FULL|CROSS [OUTER] JOIN <right_subquery>
	(ON <expr_list>)|(USING <column_list>) ..

		`ANY｜ALL`
		当指定ANY时，只返回附表中与主标中对应的第一条数据，
		当指定ALL时，返回附表中与主标中对应的所有数据
		当主表附表一一对应时ANY｜ALL结果是一样的	

		`GLOBAL`要谨慎使用，一般用于分布式

	--当使用JOIN子句时，建议用子查询过滤掉不需要的字段，然后JOIN，示例如下：
	SELECT
    CounterID,
    hits,
    visits
	FROM
	(
	    SELECT
	        CounterID,
	        count() AS hits
	    FROM test.hits
	    GROUP BY CounterID
	) ANY LEFT JOIN
	(
	    SELECT
	        CounterID,
	        sum(Sign) AS visits
	    FROM test.visits
	    GROUP BY CounterID
	) USING CounterID
	ORDER BY hits DESC
	LIMIT 10;
	--在CLickHOuse中，子查询是不允许起别名或是在其他地方引用的
		`USING` 
		--当使用USING时，using的字段必须在关联的2个表中都存在的相同字段
		--右表（子查询的结果）将会保存在内存中。如果没有足够的内存，则无法运行JOIN。
		--只能在查询中指定一个JOIN。若要运行多个JOIN，你可以将它们放入子查询中。
		--每次运行相同的JOIN查询，总是会再次计算 - 没有缓存结果。 为了避免这种情况，可以使用‘Join’引擎，它是一个预处理的Join数据结构，总是保存在内存中。更多信息，参见“Join引擎”部分。
		--在一些场景下，使用IN代替JOIN将会得到更高的效率。在各种类型的JOIN中，最高效的是ANY LEFT JOIN，然后是ANY INNER JOIN，效率最差的是ALL LEFT JOIN以及ALL INNER JOIN。

		`Null的处理`
		--JOIN的行为受 join_use_nulls 的影响。当join_use_nulls=1时，JOIN的工作与SQL标准相同。
		--如果JOIN的key是 Nullable 类型的字段，则其中至少一个存在 NULL 值的key不会被关联。


		`WHERE子句`
		`PREWHERE` -- 只支持*MERGETREE系列的表引擎，执行在PREWHERE,一般PREWHERE都用于不是主键的列

		`GROUP BY子句` `=>>这是列存储数据中最关键的部分`
		 -- GROUP BY 在CLickHOuse中对NULL值进行了优化，将NULL解释为一个值，并支持 NULL = NULL

							┌─x─┬────y─┐
							│ 1 │    2 │
							│ 2 │ ᴺᵁᴸᴸ │
							│ 3 │    2 │
							│ 3 │    3 │
							│ 3 │ ᴺᵁᴸᴸ │

		通过 SELECT sum(x) ,y from table_name group by y;查询出来的结果为：

							┌─sum(x)─┬────y─┐
							│      4 │    2 │
							│      3 │    3 │
							│      5 │ ᴺᵁᴸᴸ │
							└────────┴──────┘

							
----------------------------------------------------------------------------




