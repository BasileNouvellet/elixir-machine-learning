defmodule Hackernews do
  @behaviour Crawly.Spider

  require Logger

  @impl Crawly.Spider
  def base_url(), do: "https://news.ycombinator.com/"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        base_url()
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # Extracting pagination urls
    pagination_urls =
      response.body
      |> Floki.find("a.morelink")
      |> Floki.attribute("href")

    # Converting URLs into Crawly requests
    requests =
      pagination_urls
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    # Extracting item fields
    titles =
      response.body
      |> Floki.find("a.storylink")
      |> Enum.map(&Floki.text/1)

    ranks =
      response.body
      |> Floki.find("span.rank")
      |> Enum.map(&Floki.text/1)

    items =
      [ranks, titles]
      |> Enum.zip()
      |> Enum.map(fn {rank, title} ->
        %{
          id: rank,
          title: title
        }
      end)

    %Crawly.ParsedItem{
      :items => items,
      :requests => requests
    }
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end
