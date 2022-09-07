alias Exqlite.Sqlite3, as: DB

{:ok, conn} = DB.open("dbip_city.db")
{:ok, stmt1} = DB.prepare(conn, "select ip, lat, lon from ipv4 where ip < ? limit 1")
{:ok, stmt2} = DB.prepare(conn, "select ip, lat, lon from ipv4 where ip > ? limit 1")
{:ok, stmt3} = DB.prepare(conn, "select max(ip), lat, lon from ipv4 where ip < ? limit 1")

defmodule IP do
  use Bitwise

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

:ok = :locus.start_loader(:city, "downloads/dbip-city-lite-2022-09.mmdb")
{:ok, {{2022, 9, 1}, {0, 41, 10}}} = :locus.await_loader(:city)

:ok =
  Geolix.load_database(%{
    id: :city,
    adapter: Geolix.Adapter.MMDB2,
    source: "downloads/dbip-city-lite-2022-09.mmdb"
  })

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
