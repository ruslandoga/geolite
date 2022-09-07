defmodule Dev do
  def download_maxmind_geolite2_country do
  end

  def download_maxmind_geolite2_city do
  end

  def download_maxmind_geolite2_asn do
  end

  # https://db-ip.com/db/download/ip-to-country-lite
  def download_dbip_country_lite do
  end

  # https://db-ip.com/db/download/ip-to-city-lite
  def download_dbip_city_lite do
  end

  # https://db-ip.com/db/download/ip-to-asn-lite
  def download_dbip_asn_lite do
  end

  alias Exqlite.Sqlite3, as: DB
  alias NimbleCSV.RFC4180, as: CSV
  use Bitwise

  def sqlite_load_dbip_city_lite do
    {:ok, conn} = DB.open("dbip_city.db")

    :ok =
      DB.execute(
        conn,
        "create table if not exists ipv4 (ip int primary key, lat float, lon float) without rowid"
      )

    :ok =
      DB.execute(
        conn,
        "create table if not exists ipv6 (ip1 int, ip2 int, lat float, lon float, primary key (ip1, ip2)) without rowid"
      )

    {:ok, stmt_ipv4} = DB.prepare(conn, "insert into ipv4 (ip, lat, lon) values (?, ?, ?)")

    {:ok, stmt_ipv6} =
      DB.prepare(conn, "insert into ipv6 (ip1, ip2, lat, lon) values (?, ?, ?, ?)")

    :ok = DB.execute(conn, "begin")

    File.stream!("downloads/dbip-city-lite-2022-09.csv")
    |> CSV.parse_stream(skip_headers: false)
    |> Stream.each(fn row ->
      [from, _to, _continent, _country, _region, _city, lat, lon] = row

      case encode_ip(from) do
        {:v4, ipv4} ->
          {lat, ""} = Float.parse(lat)
          {lon, ""} = Float.parse(lon)
          :ok = DB.bind(conn, stmt_ipv4, [ipv4, lat, lon])
          :done = DB.step(conn, stmt_ipv4)

        {:v6, _ip1, _ip2} ->
          :todo
          # {lat, ""} = Float.parse(lat)
          # {lon, ""} = Float.parse(lon)
          # :ok = DB.bind(conn, stmt_ipv6, [ip1, ip2, lat, lon])
          # :done = DB.step(conn, stmt_ipv6)
      end
    end)
    |> Stream.run()

    :ok = DB.execute(conn, "commit")
    :ok = DB.release(conn, stmt_ipv4)
    :ok = DB.release(conn, stmt_ipv6)
    :ok = DB.close(conn)
  end

  def encode_ip(ip) when is_binary(ip) do
    case :inet.parse_address(to_charlist(ip)) do
      {:ok, {a, b, c, d}} ->
        {:v4, (a <<< 24) + (b <<< 16) + (c <<< 8) + d}

      {:ok, {a, b, c, d, e, f, g, h}} ->
        {:v6, (a <<< 24) + (b <<< 16) + (c <<< 8) + d, (e <<< 24) + (f <<< 16) + (g <<< 8) + h}
    end
  end
end
