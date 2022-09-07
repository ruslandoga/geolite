alias Exqlite.Sqlite3, as: DB

mem = fn step ->
  IO.puts("[#{step}] memory usage: #{Float.round(:erlang.memory(:total) / 1_000_000, 2)}MB")
end

gc = fn -> Process.list() |> Enum.each(&:erlang.garbage_collect/1) end
mem.("init")
gc.()
mem.("init, after gc")

{:ok, conn} = DB.open("dbip_city.db", mode: :readonly)
:ok = DB.execute(conn, "pragma cache_size = -2000")
:ok = DB.execute(conn, "pragma temp_store = memory")
{:ok, stmt1} = DB.prepare(conn, "select ip, lat, lon from ipv4 where ip < ? limit 1")
{:ok, stmt2} = DB.prepare(conn, "select ip, lat, lon from ipv4 where ip > ? limit 1")
{:ok, stmt3} = DB.prepare(conn, "select max(ip), lat, lon from ipv4 where ip < ? limit 1")

mem.("loaded sqlite")
gc.()
mem.("loaded sqlite, after gc")

defmodule IP do
  import Bitwise

  def rand_ipv4 do
    ipv4 = :rand.uniform(4_294_967_296)
    decode_unsigned(ipv4)
  end

  def decode_unsigned(ipv4) when is_integer(ipv4) do
    a = ipv4 >>> 24
    rest = ipv4 - (a <<< 24)
    b = rest >>> 16
    rest = rest - (b <<< 16)
    c = rest >>> 8
    d = rest - (c <<< 8)
    "#{a}.#{b}.#{c}.#{d}"
  end

  def encode_unsigned(ipv4) when is_binary(ipv4) do
    {:ok, {a, b, c, d}} = :inet.parse_address(to_charlist(ipv4))
    (a <<< 24) + (b <<< 16) + (c <<< 8) + d
  end

  def lookup(conn, stmt, ip) do
    :ok = DB.bind(conn, stmt, [IP.encode_unsigned(ip)])
    DB.multi_step(conn, stmt, 2)
  end
end

mem.("before locus")
gc.()
mem.("before locus, after gc")

:ok = :locus.start_loader(:city, "downloads/dbip-city-lite-2022-09.mmdb")
{:ok, {{2022, 9, 1}, {0, 41, 10}}} = :locus.await_loader(:city)

mem.("after locus")
gc.()
mem.("after locus, after gc")

:ok =
  Geolix.load_database(%{
    id: :city,
    adapter: Geolix.Adapter.MMDB2,
    source: "downloads/dbip-city-lite-2022-09.mmdb"
  })

mem.("after geolix")
gc.()
mem.("after geolix, after gc")

Benchee.run(
  %{
    # "control" => fn -> IP.rand_ipv4() end,
    # "decode/encode" => fn -> IP.rand_ipv4() |> IP.encode_unsigned() end,

    # "ip < ?" => fn -> IP.lookup(conn, stmt1, IP.rand_ipv4()) end,
    # "ip > ?" => fn -> IP.lookup(conn, stmt2, IP.rand_ipv4()) end,
    # "max(ip) < ?" => fn -> IP.lookup(conn, stmt3, IP.rand_ipv4()) end,

    "geolite" => fn -> IP.lookup(conn, stmt3, IP.rand_ipv4()) end,
    "locus" => fn -> :locus.lookup(:city, IP.rand_ipv4()) end,
    "geolix" => fn -> Geolix.lookup(IP.rand_ipv4(), where: :city) end
  },
  memory_time: 2
)

mem.("after benchee")
gc.()
mem.("after benchee, after gc")
