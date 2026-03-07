# polars v1.14+

Fast DataFrame library written in Rust. Supports lazy evaluation, parallel execution, and zero-copy operations.

```
pip install polars
pip install polars[all]  # includes connectors (parquet, csv, cloud, etc.)
```

## Quick Start

```python
import polars as pl

df = pl.read_csv("data.csv")
result = (
    df.lazy()
    .filter(pl.col("age") > 25)
    .group_by("department")
    .agg(pl.col("salary").mean().alias("avg_salary"))
    .sort("avg_salary", descending=True)
    .collect()
)
```

## Core API

### Reading Data

```python
# CSV
df = pl.read_csv("data.csv")
lf = pl.scan_csv("data.csv")          # lazy -- preferred

# Parquet
df = pl.read_parquet("data.parquet")
lf = pl.scan_parquet("data.parquet")   # lazy -- preferred

# From Python
df = pl.DataFrame({"a": [1, 2, 3], "b": ["x", "y", "z"]})
df = pl.from_dict({"a": [1, 2, 3]})
df = pl.from_records([{"a": 1, "b": 2}, {"a": 3, "b": 4}])
df = pl.from_pandas(pandas_df)
```

### Writing Data

```python
df.write_csv("out.csv")
df.write_parquet("out.parquet")
df.write_json("out.json")
df.to_pandas()          # -> pandas DataFrame
df.to_dicts()           # -> list[dict]
```

### Select and Expressions

```python
# Select columns
df.select("name", "age")
df.select(pl.col("name"), pl.col("age") + 1)

# With columns (add/replace)
df.with_columns(
    (pl.col("price") * pl.col("qty")).alias("total"),
    pl.col("name").str.to_uppercase().alias("NAME"),
    pl.lit(True).alias("active"),
)

# Rename
df.rename({"old_name": "new_name"})

# Drop
df.drop("col1", "col2")
```

### Filter

```python
df.filter(pl.col("age") > 25)
df.filter((pl.col("age") > 25) & (pl.col("city") == "NYC"))
df.filter(pl.col("name").is_in(["alice", "bob"]))
df.filter(pl.col("email").str.contains("@gmail"))
df.filter(pl.col("value").is_not_null())
```

### Group By and Aggregate

```python
df.group_by("department").agg(
    pl.col("salary").mean().alias("avg_salary"),
    pl.col("salary").max().alias("max_salary"),
    pl.col("name").count().alias("headcount"),
    pl.col("name").first().alias("first_hire"),
)

# Multiple group keys
df.group_by("dept", "role").agg(pl.col("salary").sum())
```

### Sort

```python
df.sort("age")
df.sort("age", descending=True)
df.sort("dept", "age", descending=[False, True])
```

### Join

```python
df1.join(df2, on="id", how="inner")       # inner join
df1.join(df2, on="id", how="left")        # left join
df1.join(df2, left_on="uid", right_on="user_id", how="inner")

# Anti join (rows in df1 not in df2)
df1.join(df2, on="id", how="anti")
```

### Lazy Frames

```python
# Lazy evaluation -- builds a query plan, optimizes, then executes
lf = df.lazy()                              # DataFrame -> LazyFrame
lf = pl.scan_csv("big.csv")                # scan is already lazy

result = (
    lf.filter(pl.col("status") == "active")
    .group_by("region")
    .agg(pl.col("revenue").sum())
    .sort("revenue", descending=True)
    .limit(10)
    .collect()                               # execute and return DataFrame
)

# Explain the query plan
print(lf.explain())

# Streaming for larger-than-memory
result = lf.collect(streaming=True)
```

### Common Expressions

```python
pl.col("x")                    # reference column
pl.lit(42)                     # literal value
pl.col("x").cast(pl.Int64)    # type cast
pl.col("x").fill_null(0)      # null handling
pl.col("x").is_null()
pl.col("s").str.lengths()     # string ops
pl.col("s").str.replace("a", "b")
pl.col("d").dt.year()         # datetime ops
pl.col("d").dt.month()
pl.when(pl.col("x") > 0).then(pl.lit("pos")).otherwise(pl.lit("neg")).alias("sign")
```

## Examples

### ETL pipeline

```python
orders = pl.scan_parquet("orders/*.parquet")
customers = pl.scan_csv("customers.csv")

report = (
    orders
    .filter(pl.col("date") >= "2025-01-01")
    .join(customers.lazy(), on="customer_id", how="inner")
    .group_by("region")
    .agg(
        pl.col("amount").sum().alias("total_revenue"),
        pl.col("order_id").n_unique().alias("order_count"),
    )
    .sort("total_revenue", descending=True)
    .collect()
)
report.write_parquet("report.parquet")
```

### Window functions

```python
df.with_columns(
    pl.col("salary").mean().over("department").alias("dept_avg"),
    pl.col("salary").rank().over("department").alias("dept_rank"),
)
```

### Pivot / unpivot

```python
# Pivot (wide)
df.pivot(on="product", index="date", values="sales", aggregate_function="sum")

# Unpivot (long)
df.unpivot(on=["jan", "feb", "mar"], index="product", variable_name="month", value_name="sales")
```

## Pitfalls

1. **scan_csv not read_csv().lazy()**: `read_csv().lazy()` materializes the entire file first, defeating the purpose. Always use `scan_csv` / `scan_parquet` for lazy evaluation.
2. **Expressions, not lambdas**: `df.filter(lambda row: row["x"] > 5)` does not work. Use `df.filter(pl.col("x") > 5)`. All operations go through the expression API.
3. **No index**: Polars has no row index. Use `with_row_index()` if you need one.
4. **Column names are strings**: `df["col"]` returns a Series. `df[0]` returns a Series by position. There is no `.iloc` / `.loc`.
5. **Immutable DataFrames**: Operations return new DataFrames. `df.sort("x")` does not modify `df` in place.
6. **Null vs NaN**: Polars distinguishes `null` (missing) from `NaN` (float not-a-number). Use `is_null()` for missing data, not `is_nan()`.
7. **collect() triggers execution**: Chaining lazy operations has zero cost. Only `collect()` runs the query. Call it once at the end.
