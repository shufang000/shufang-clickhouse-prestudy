

# ClickHouse

前言：

clickhouse是当今主流的适用于海量数据进行OLAP的主流工具，强大的功能来自clickhouse的独特特性，能够满足高吞吐、低延迟的OLAP处理。

1.列式存储数据

2.支持数据压缩，数据物理存储更加紧凑

3.充分利用机器的CPU，进行极佳的并行处理

4.还可以部署分布式集群，进行联机OLAP

5.SQL支持

6.查询引擎、存储引擎协同工作

7.支持index索引

8.适合online查询

9.支持数据备份

## 1.ClickHouse单机的安装（centos7或redhat 4.8.5）

- **clickhouse安装的前提条件**

```properties
1.在/etc/security/limits.conf
		/etc/security/limits.d/90-nproc.conf
这2个文件中添加以下内容：
	* soft nofile 65536     # 决定某个框架能打开的最多文件数
	* hard nofile 65536
	* soft noproc 131072		# 决定某个框架能打开的最大进程数
	* hard noproc 131072
	
	# 查看取消限制的结果是否生效
	ulimit -n 或者[-a] 
	
----------------------------------------------------

2. vim /etc/selinux/config
将 SELINUX=disable

3. 关闭防火墙
servive iptables stop
service iptables status

4.安装依赖
[root@clickhouse ~]# yum install -y libtool
[root@clickhouse ~]# yum install -y *unixODBC*

[root@clickhouse ~] yum search libicu
[root@clickhouse ~]# yum install libicu.x86_64
到这里clickhouse的前提条件就准备好了！
```

- **clickhouse的官网、下载地址**

```properties
官网：https://clickhouse.yandex/  
下载地址：https://packagecloud.io/altinity/clickhouse

# 依次下载以下内容，下面均是最新版本
# 官网推荐使用rpm包进行安装，但是貌似没有提供rpm的下载路径，所有选择从Altinity公司提供的资源进行下载
wget --content-disposition https://packagecloud.io/Altinity/clickhouse/packages/el/7/clickhouse-server-common-19.15.4.10-1.el7.x86_64.rpm/download.rpm

wget --content-disposition https://packagecloud.io/Altinity/clickhouse/packages/el/7/clickhouse-common-static-19.15.4.10-1.el7.x86_64.rpm/download.rpm

wget --content-disposition https://packagecloud.io/Altinity/clickhouse/packages/el/7/clickhouse-server-19.15.4.10-1.el7.x86_64.rpm/download.rpm

wget --content-disposition https://packagecloud.io/Altinity/clickhouse/packages/el/7/clickhouse-test-19.15.4.10-1.el7.x86_64.rpm/download.rpm

wget --content-disposition https://packagecloud.io/Altinity/clickhouse/packages/el/7/clickhouse-client-19.15.4.10-1.el7.x86_64.rpm/download.rpm

wget --content-disposition https://packagecloud.io/Altinity/clickhouse/packages/el/7/clickhouse-debuginfo-19.15.4.10-1.el7.x86_64.rpm/download.rpm

如果文件通过wget不能下载的话，就直接通过下载到本地然后打包的方式进行手动上传。 
# 走到这里说明clickhouse的rpm文件基本安装完毕。
```

## 2.ClickHouse数据类型

```sql
1.整型数据
	有符号整型：Int8 Int16 Int32 Int64   				范围->（-2^n-1 ~ 2^n-1+1 ）
	无符号整型：UInt8 UInt16 UInt32 UInt64  		范围->（0 ~ 2^n + 1）

2.浮点类型
	Float32 - float 			
	Float64 - double
	-- 建议尽可能以整数形式存储数据。例如，将固定精度的数字转换为整数值，如时间用毫秒为单位表示，因为浮点型			进行计算时可能引起四舍五入的误差
	
3.布尔型
	没有单独的类型来存储布尔值。可以使用 UInt8 类型，取值限制为 0 或 1。
	
4.枚举类型
	包括 Enum8 和 Enum16 类型
	Enum8 用 'String'= Int8 对描述。
	Enum16 用 'String'= Int16 对描述
	
	CREATE TABLE t_enum(
    x Enum8('hello' = 1, 'world' = 2)
	)ENGINE = TinyLog    -- 创建表、确定引擎
	
	INSERT INTO t_enum VALUES ('hello'), ('world'), ('hello')   -- 插入数据
	
	SELECT * FROM t_enum
  ┌─x─────┐
  │ hello │
  │ world │
  │ hello │
  └───────┘
  SELECT CAST(x, 'Int8') FROM t_enum

  ┌─CAST(x, 'Int8')─┐
  │               1 │
  │               2 │
  │               1 │
  └─────────────────┘
  
  5.字符串类型   -- 一般来说String还是用得比FixedString要多，因为方便一些
  String		  -- 不定长字符串类型
  FixedString(N)  -- 不定长字符串类型
  
  6.数组类型
  Array(T)：由 T 类型元素组成的数组。
	T 可以是任意类型，包含数组类型。 但不推荐使用多维数组，ClickHouse 对多维数组的支持有限。例如，不能在 	MergeTree 表中存储多维数组。可以使用array函数来创建数组：
	-- array(T)
	SELECT array(1,2) AS x,toTypeName(x)
	
  ┌─x─────┬─toTypeName(array(1, 2))─┐
  │ [1,2] │ Array(UInt8)            │
  └───────┴─────────────────────────┘
  SELECT [1,2] AS x,toTypeName(x)
  
  ┌─x─────┬─toTypeName([1,2])      ─┐
  │ [1,2] │ Array(UInt8)            │
  └───────┴─────────────────────────┘

	7.元祖
	Tuple(T1,T2,T3....) 其中每一个元素都可以是不同的数据类型
	SELECT tuple(1,'a') AS x, toTypeName(x)
	
  ┌─x───────┬─toTypeName(tuple(1, 'a'))─┐
  │ (1,'a') │ Tuple(UInt8, String)      │
  └─────────┴───────────────────────────┘
  
  8.Date类型
  日期类型，用两个字节存储，表示从 1970-01-01 (无符号) 到当前的日期值。
  还有很多数据结构，可以参考官方文档：
  -- https://clickhouse.yandex/docs/zh/data_types/
  
  -- clickhouse-client -m -h -p........
```



## 3.ClickHouse表引擎

表引擎（即表的类型）决定了：

1）数据的存储方式和位置，写到哪里以及从哪里读取数据

2）支持哪些查询以及如何支持。

3）并发数据访问。

4）索引的使用（如果存在）。

5）是否可以执行多线程请求。

6）数据复制参数。

ClickHouse的表引擎有很多，下面介绍其中几种，对其他引擎有兴趣的可以去查阅官方文档：https://clickhouse.yandex/docs/zh/operations/table_engines/

### 3.1、TinyLog

```SQL
-- 最简单的表引擎，
- 用于将数据存储在磁盘上。每列都存储在单独的压缩文件中，写入时，数据将附加到文件末尾。
	该引擎没有并发控制 
- 如果同时从表中读取和写入数据，则读取操作将抛出异常；
- 如果同时写入多个查询中的表，则数据将被破坏。
	这种表引擎的典型用法是 write-once：首先只写入一次数据，然后根据需要多次读取。此引擎适用于相对较小的表（建议最多1,000,000行）。如果有许多小表，则使用此表引擎是适合的，因为它比需要打开的文件更少。当拥有大量小表时，可能会导致性能低下。      不支持索引。
案例：创建一个TinyLog引擎的表并插入一条数据
:)create table t (a UInt16, b String) ENGINE=TinyLog;
:)insert into t (a, b) values (1, 'abc');
此时我们到保存数据的目录/var/lib/clickhouse/data/default/t中可以看到如下目录结构：
[root@hostname t]# ls
a.bin  b.bin  sizes.json
a.bin 和 b.bin 是压缩过的对应的列的数据， sizes.json 中记录了每个 *.bin 文件的大小：
[root@hadoop102 t]# cat sizes.json 
{"yandex":{"a%2Ebin":{"size":"28"},"b%2Ebin":{"size":"30"}}}
```

### 3.2、Memory

```sql
-- 内存引擎
数据以未压缩的原始形式直接保存在内存当中，服务器重启数据就会消失。读写操作不会相互阻塞，不支持索引。简单查询下有非常非常高的性能表现（超过10G/s）。
一般用到它的地方不多，除了用来测试，就是在需要非常高的性能，同时数据量又不太大（上限大概 1 亿行）的场景。
```

### 3.3、Merge引擎

Merge 引擎 (*不要跟 MergeTree 引擎混淆)* 本身不存储数据，但可用于同时从任意多个其他的表中读取数据。 读是自动并行的，不支持写入。读取时，那些被真正读取到数据的表的索引（如果有的话）会被使用。 
Merge 引擎的参数：一个数据库名和一个用于匹配表名的正则表达式。

```SQL
案例：先建t1，t2，t3三个表，然后用 Merge 引擎的 t 表再把它们链接起来。
:)create table t1 (id UInt16, name String) ENGINE=TinyLog;
:)create table t2 (id UInt16, name String) ENGINE=TinyLog;
:)create table t3 (id UInt16, name String) ENGINE=TinyLog;

:)insert into t1(id, name) values (1, 'first');
:)insert into t2(id, name) values (2, 'second');
:)insert into t3(id, name) values (3, 'i am in t3');

:)create table t (id UInt16, name String) ENGINE=Merge(currentDatabase(), '^t');

:) select * from t;
┌─id─┬─name─┐
│  2 │ second │
└────┴──────┘
┌─id─┬─name──┐
│  1 │ first │
└────┴───────┘
┌─id─┬─name───────┐
│ 3	 │ i am in t3 │
└────┴────────────┘
```

### 3.4、MergeTree

Clickhouse 中最强大的表引擎当属 MergeTree （合并树）引擎及该系列（*MergeTree）中的其他引擎。MergeTree 引擎系列的基本理念如下。当你有巨量数据要插入到表中，你要高效地一批批写入数据片段，并希望这些数据片段在后台按照一定规则合并。相比在插入时不断修改（重写）数据进存储，这种策略会高效很多。

```SQL
格式：
ENGINE [=] MergeTree(date-column ,[sampling_expression], (primary, key), index_granularity)
参数解读：
date-column — 类型为 Date 的列名。ClickHouse 会自动依据这个列按月创建分区。分区名格式为 "YYYYMM" 。
sampling_expression — 采样表达式。
(primary, key) — 主键。类型为Tuple()
index_granularity — 索引粒度。即索引中相邻”标记”间的数据行数。设为 8192 可以适用大部分场景。
案例：
create table mt_table (date  Date, id UInt8, name String) ENGINE=MergeTree(date, (id, name), 8192);

insert into mt_table values ('2019-05-01', 1, 'zhangsan');
insert into mt_table values ('2019-06-01', 2, 'lisi');
insert into mt_table values ('2019-05-03', 3, 'wangwu');
在/var/lib/clickhouse/data/default/mt_tree下可以看到：
[root@hostname mt_table]# ls
20190501_20190501_2_2_0  20190503_20190503_6_6_0  20190601_20190601_4_4_0  detached

随便进入一个目录：
[root@hostname 20190601_20190601_4_4_0]# ls
checksums.txt  columns.txt  date.bin  date.mrk  id.bin  id.mrk  name.bin  name.mrk  primary.idx
- *.bin是按列保存数据的文件
- *.mrk保存块偏移量
- primary.idx保存主键索引
```

### 3.5、ReplacingMergeTree

这个引擎是在 MergeTree 的基础上，添加了“处理重复数据”的功能，该引擎和MergeTree的不同之处在于它	会删除具有相同主键的重复项。数据的去重只会在合并的过程中出现。合并会在未知的时间在后台进行，所	以你无法预先作出计划。有一些数据可能仍未被处理。因此，ReplacingMergeTree 适用于在后台清除重复的	数据以节省空间，但是它不保证没有重复的数据出现。

```SQL
格式：
ENGINE [=] ReplacingMergeTree(date-column [, sampling_expression], (primary, key), index_granularity, [ver])
可以看出他比MergeTree只多了一个ver，这个ver指代版本列。
案例：
create table rmt_table (date  Date, id UInt8, name String,point UInt8) ENGINE= ReplacingMergeTree(date, (id, name), 8192,point);

插入一些数据：
insert into rmt_table values ('2019-07-10', 1, 'a', 20);
insert into rmt_table values ('2019-07-10', 1, 'a', 30);
insert into rmt_table values ('2019-07-11', 1, 'a', 20);
insert into rmt_table values ('2019-07-11', 1, 'a', 30);
insert into rmt_table values ('2019-07-11', 1, 'a', 10);

等待一段时间或optimize table rmt_table手动触发merge，后查询
:) select * from rmt_table;
┌───────date─┬─id─┬─name─┬─point─┐
│ 2019-07-11 │  1 │ a    │    30 │
└────────────┴────┴──────┴───────┘
```

### 3.6、SummingMergeTree

该引擎继承自 MergeTree。区别在于，当合并 SummingMergeTree 表的数据片段时，ClickHouse 会把所有具有相同主键的行合并为一行，该行包含了被合并的行中具有数值数据类型的列的汇总值。如果主键的组合方式使得单个键值对应于大量的行，则可以显著的减少存储空间并加快数据查询的速度，对于不可加的列，会取一个最先出现的值。

```SQL
语法：
ENGINE [=] SummingMergeTree(date-column [, sampling_expression], (primary, key), index_granularity, [columns])
columns — 包含将要被汇总的列的列名的元组
案例：
create table smt_table (date Date, name String, a UInt16, b UInt16) ENGINE=SummingMergeTree(date, (date, name), 8192, (a))
插入数据：
insert into smt_table (date, name, a, b) values ('2019-07-10', 'a', 1, 2);
insert into smt_table (date, name, a, b) values ('2019-07-10', 'b', 2, 1);
insert into smt_table (date, name, a, b) values ('2019-07-11', 'b', 3, 8);
insert into smt_table (date, name, a, b) values ('2019-07-11', 'b', 3, 8);
insert into smt_table (date, name, a, b) values ('2019-07-11', 'a', 3, 1);
insert into smt_table (date, name, a, b) values ('2019-07-12', 'c', 1, 3);
等待一段时间或optimize table smt_table手动触发merge，后查询
:) select * from smt_table 

┌───────date─┬─name─┬─a─┬─b─┐
│ 2019-07-10 │ a    │ 1 │ 2 │
│ 2019-07-10 │ b    │ 2 │ 1 │
│ 2019-07-11 │ a    │ 3 │ 1 │
│ 2019-07-11 │ b    │ 6 │ 8 │
│ 2019-07-12 │ c    │ 1 │ 3 │
└────────────┴──────┴───┴───┘

发现2019-07-11，b的a列合并相加了，b列取了8（因为b列为8的数据最先插入）。
```

### 3.7、 Distributed

分布式引擎，本身不存储数据, 但可以在多个服务器上进行分布式查询。 读是自动并行的。读取时，远程服务器表的索引（如果有的话）会被使用。 

**Distributed(cluster_name, database, table [, sharding_key])**

参数解析：

cluster_name  - 服务器配置文件中的集群名,在/etc/metrika.xml中配置的

database – 数据库名

table – 表名

sharding_key – 数据分片键

```SQL
案例演示：
1）在hadoop102，hadoop103，hadoop104上分别创建一个表t
:)create table t(id UInt16, name String) ENGINE=TinyLog;
2）在三台机器的t表中插入一些数据
:)insert into t(id, name) values (1, 'zhangsan');
:)insert into t(id, name) values (2, 'lisi');
3）在hadoop102上创建分布式表
:)create table dis_table(id UInt16, name String) ENGINE=Distributed(perftest_3shards_1replicas, default, t, id);
4）往dis_table中插入数据
:) insert into dis_table select * from t
5）查看数据量
:) select count() from dis_table FROM dis_table 

┌─count()─┐
│       8 │
└─────────┘
:) SELECT count() FROM t 

┌─count()─┐
│       3 │
└─────────┘
可以看到每个节点大约有1/3的数据
```

## 4.与mysql建立数据通道

### 4.1、clickhouse通过查询引擎直接查mysql数据

下面的方式只用到了clickhouse的查询引擎，数据还是存储在mysql中，并没有同步过来

```SQL
方式一、 CREATE DATABASE mysql_db ENGINE=MySQL(,,,,,)
方式二、 CREATE TABLE table_name() ENGINE=MySQL('host:port','database_name','table_name','user','password')

--以上方式使用之前可以通过Mysql所在节点上用：
mysql -uusername -hhostname -p  --来测试mysql是否支持远程连接，如果不支持，可以参考以下的方法：
·Linux环境 Mysql新建用户和数据库并授权
	1.登录mysql
#mysql -u root -p

2.新增用户
insert into mysql.user(Host,User,Password) values("localhost","xxx",password("***"));
注释：xxx为新建用户名，***为用户密码

3.执行该句后，还需要刷新权限表
flush privileges;

4.新建数据库并赋予用户权限
create database dbtest；

全部授权：
允许本地登录
grant all privileges on dbtest.* to xxx@localhost identified by "*";
允许任何主机登录
grant all privileges on dbtest. to xxx@'%' identified by "";
部分授权：
grant select,update on dbtest.* to xxx@localhost identified by "***";

5.赋予权限，还需要再刷新权限表
flush privileges;

6.通过sql语句查询出新增结果
select user,host,password from mysql.user;

7.删除用户
delete from user where user=‘xxx’;
flush privileges;

8.删除数据库
drop database dbtest;

9.修改密码
update mysql.user set password=password(‘新密码’) where User='xxx' and Host='localhost';
flush privileges;
```

### 4.2、clickhouse通过存储引擎拉取mysql中数据

```SQL
-- sql方式导入
insert into ck_db_name.ck_tb_name (字段1, 字段2, ...) 
SELECT 字段1, 字段2, ...
FROM mysql('host:port', 'database_name', 'table_name', 'user_name', 'passport')

---------
-- 也可以用Python来写入：
from clickhouse_driver import Client

client = Client(host, port, user, database, password)
sql = """
insert into ck_db_name.ck_tb_name (字段1, 字段2, ...) 
SELECT 字段1, 字段2, ...
FROM mysql('host:port', 'database_name', 'table_name', 
			'user_name', 'passport')"""
try:     
    client.execute(sql, types_check=True)
except Exception as e:
    print(e)	


-------
-- 简单从mysql同步数据的sql
-- 总数据900M，300W行，耗时26.571s，插入速度为108000 row/s，33.78M/s
use public_db;

insert into person 
select pkid,id,org_id,position_id,identity_num,name,gender,
nationality,native_place,native_place_code,blood_type,birth_place,
birth_place_code,
birth_date,
enlist_date,
retirement_date,
work_start_date,
officer_start_date,
residence_character,
print_flag,
hire_date,
ent_date,
ent_user,
mod_date,
mod_user,
start_date,
end_date,
status,
deleted_flag,
user_id
from
mysql('10.10.43.25:3306','ZGB_DEV','person','root','Pase2019');

```

## 5.从CSV文件导入数据

```shell
cat xxx.csv | clickhouse-client --query ‘insert into table_name FORMAT CSV’
history ｜ grep clickhouse-client > log.txt. # 查看clickhouse本机命令历史及时间
```

官方clickhouse文档： https://clickhouse.yandex/docs/en/introduction/distinctive_features/

### 5.1从csv插入1.6亿+条测试数据及测试结果

-- 本测试结果是通过16G 8cores的机器跑出来的测试结果

```sql
SELECT avg(c1)
FROM
(
    SELECT Year, Month, count(*) AS c1
    FROM ontime
    GROUP BY Year, Month
);       -- 耗时：0.362s


SELECT DayOfWeek, count(*) AS c
FROM ontime
WHERE Year>=2000 AND Year<=2008
GROUP BY DayOfWeek
ORDER BY c DESC;  -- 耗时：0.083s


SELECT DayOfWeek, count(*) AS c
FROM ontime
WHERE DepDelay>10 AND Year>=2000 AND Year<=2008
GROUP BY DayOfWeek
ORDER BY c DESC;  -- 耗时：0.21s


SELECT Origin, count(*) AS c
FROM ontime
WHERE DepDelay>10 AND Year>=2000 AND Year<=2008
GROUP BY Origin
ORDER BY c DESC
LIMIT 10;   -- 0.279s

SELECT Carrier, count(*)
FROM ontime
WHERE DepDelay>10 AND Year=2007
GROUP BY Carrier
ORDER BY count(*) DESC; --耗时：0.036s


SELECT Carrier, c, c2, c*100/c2 as c3
FROM
(
    SELECT
        Carrier,
        count(*) AS c
    FROM ontime
    WHERE DepDelay>10
        AND Year=2007
    GROUP BY Carrier
)
 JOIN
(
    SELECT
        Carrier,
        count(*) AS c2
    FROM ontime
    WHERE Year=2007
    GROUP BY Carrier
) USING Carrier
ORDER BY c3 DESC;    -- 耗时：0.061s

-- better query of below
SELECT Carrier, avg(DepDelay>10)*100 AS c3
FROM ontime
WHERE Year=2007
GROUP BY Carrier
ORDER BY Carrier; -- 耗时: 0.038s 


SELECT Carrier, c, c2, c*100/c2 as c3
FROM
(
    SELECT
        Carrier,
        count(*) AS c
    FROM ontime
    WHERE DepDelay>10
        AND Year>=2000 AND Year<=2008
    GROUP BY Carrier
)
 JOIN
(
    SELECT
        Carrier,
        count(*) AS c2
    FROM ontime
    WHERE Year>=2000 AND Year<=2008
    GROUP BY Carrier
) USING Carrier
ORDER BY c3 DESC;  --耗时:0.338s

-- better query of below
SELECT Carrier, avg(DepDelay>10)*100 AS c3
FROM ontime
WHERE Year>=2000 AND Year<=2008
GROUP BY Carrier
ORDER BY Carrier;   -- 耗时:0.210s


SELECT Year, c1/c2
FROM
(
    select
        Year,
        count(*)*100 as c1
    from ontime
    WHERE DepDelay>10
    GROUP BY Year
)
JOIN
(
    select
        Year,
        count(*) as c2
    from ontime
    GROUP BY Year
) USING (Year)   --耗时:0.555s
ORDER BY Year;

-- better query of below
SELECT Year, avg(DepDelay>10)
FROM ontime
GROUP BY Year
ORDER BY Year;  -- 耗时:0.347s


SELECT DestCityName, uniqExact(OriginCityName) AS u 
FROM ontime
WHERE Year >= 2000 and Year <= 2010
GROUP BY DestCityName
ORDER BY u DESC LIMIT 10;  -- 耗时:1.193s


SELECT Year, count(*) AS c1
FROM ontime
GROUP BY Year;   --耗时:0.146s


SELECT
   min(Year), max(Year), Carrier, count(*) AS cnt,
   sum(ArrDelayMinutes>30) AS flights_delayed,
   round(sum(ArrDelayMinutes>30)/count(*),2) AS rate
FROM ontime
WHERE
   DayOfWeek NOT IN (6,7) AND OriginState NOT IN ('AK', 'HI', 'PR', 'VI')
   AND DestState NOT IN ('AK', 'HI', 'PR', 'VI')
   AND FlightDate < '2010-01-01'
GROUP by Carrier
HAVING cnt>100000 and max(Year)>1990
ORDER by rate DESC
LIMIT 1000;    --耗时: 1.104s


-- bonus
SELECT avg(cnt)
FROM
(
    SELECT Year,Month,count(*) AS cnt
    FROM ontime
    WHERE DepDel15=1
    GROUP BY Year,Month
);

SELECT avg(c1) FROM
(
    SELECT Year,Month,count(*) AS c1
    FROM ontime
    GROUP BY Year,Month
);

SELECT DestCityName, uniqExact(OriginCityName) AS u
FROM ontime
GROUP BY DestCityName
ORDER BY u DESC
LIMIT 10;

SELECT OriginCityName, DestCityName, count() AS c
FROM ontime
GROUP BY OriginCityName, DestCityName
ORDER BY c DESC
LIMIT 10;

SELECT OriginCityName, count() AS c
FROM ontime
GROUP BY OriginCityName
ORDER BY c DESC
LIMIT 10;
----------------------------------------------------
SELECT \
    OriginCityName, \
    DestCityName, \
    count(*) AS flights, \
    bar(flights, 0, 20000, 40) \
FROM ontime \
WHERE Year = 2015 \
GROUP BY \
    OriginCityName, \
    DestCityName \
ORDER BY flights DESC \    --耗时：0.130s
LIMIT 20;

SELECT \
    OriginCityName, \
    count(*) AS flights \
FROM ontime \
GROUP BY OriginCityName \
ORDER BY flights DESC \
LIMIT 20;         --耗时：0.949s

SELECT \
    OriginCityName, \
    uniq(Dest) As u \
FROM ontime \
GROUP BY OriginCityName \
ORDER BY u DESC \
LIMIT 20;  --耗时:1.518s


SELECT \
    DayOfWeek, \
    count() AS c, \
    avg(DepDelay > 60) AS delays \
FROM ontime \
GROUP BY DayOfWeek \
ORDER BY DayOfWeek ASC;  --耗时:0.436s


SELECT \
    OriginCityName, \
    count() AS c, \
    avg(DepDelay > 60) AS delays \
FROM ontime \
GROUP BY OriginCityName \
HAVING c > 100000 \
ORDER BY delays DESC \
LIMIT 20;   --耗时: 0.377s


SELECT \
    OriginCityName, \
    DestCityName, \
    count(*) AS flights, \
    avg(AirTime) As duration \
FROM ontime \
GROUP BY \
    OriginCityName, \
    DestCityName \
ORDER BY duration DESC \
LIMIT 20;    --耗时: 12.407s 、2.770s


SELECT \
    Carrier, \
    count() AS c, \
    round(quantileTDigest(0.99)(DepDelay), 2) AS q \
FROM ontime \
GROUP BY Carrier \
ORDER BY q DESC;   --耗时: 1.414s


SELECT \
    Carrier, \
    min(Year), \
    max(Year), \
    count() \
FROM ontime \
GROUP BY Carrier \
HAVING max(Year) < 2015 \
ORDER BY count() DESC;  --耗时: 0.390s


SELECT \
    DestCityName, \
    sum(Year = 2014) AS c2014, \
    sum(Year = 2015) AS c2015, \
    c2015 / c2014 AS diff \
FROM ontime \
WHERE Year IN (2014, 2015) \
GROUP BY DestCityName \
HAVING (c2014 > 10000) AND (c2015 > 1000) AND (diff > 1) \
ORDER BY diff DESC;   --耗时: 0.1s


SELECT \
    DestCityName, \
    any(total), \
    avg(abs((monthly * 12) - total) / total) AS avg_month_diff \
FROM \
( \
    SELECT \
        DestCityName, \
        count() AS total \
    FROM ontime \
    GROUP BY DestCityName \
    HAVING total > 100000 \
) ALL INNER JOIN \
( \
    SELECT \
        DestCityName, \
        Month, \
        count() AS monthly \
    FROM ontime \
    GROUP BY \
        DestCityName, \
        Month \
    HAVING monthly > 10000 \
) USING (DestCityName) \
GROUP BY DestCityName \
ORDER BY avg_month_diff DESC \
LIMIT 20;   --耗时: 2.389s
 
```

## 6.jdbc接口访问权限问题解决

```xml
/etc/clickhouse-server/config.xml

<!-- Listen specified host. use :: (wildcard IPv6 address), if you want to accept connections both with IPv4 and IPv6 from everywhere. -->
    <!--<listen_host>::</listen_host>       -->
    <!-- Same for hosts with disabled ipv6: -->
    <!-- <listen_host>0.0.0.0</listen_host> -->

    <!-- Default values - try listen localhost on ipv4 and ipv6: -->
    
-- 注释掉以下2行
    <!--
    <listen_host>::1</listen_host>
    <listen_host>127.0.0.1</listen_host>
    -->

    <!-- Don't exit if ipv6 or ipv4 unavailable, but listen_host with this protocol specified -->
    <!-- <listen_try>0</listen_try> -->

```

