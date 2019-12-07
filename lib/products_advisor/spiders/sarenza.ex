defmodule Sarenza do
  @behaviour Crawly.Spider

  require Logger

  @impl Crawly.Spider
  def base_url(), do: "https://www.sarenza.com"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://www.sarenza.com/tout-chaussure-homme"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # TODO: could crawl also through product page (see Harveynorman)

    # Extracting product urls
    product_urls =
      response.body
      |> Floki.find("a.product-link")
      |> Floki.attribute("href")

    # Converting URLs into Crawly requests
    requests =
      product_urls
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    # Extracting item fields
    title =
      response.body
      |> Floki.find("h1.infos")
      |> Floki.filter_out("a")
      |> Floki.filter_out("br")
      |> Floki.text()
      |> String.trim()

    brand =
      response.body
      |> Floki.find("h1.infos a.brand")
      |> Floki.text()
      |> String.trim()

    id =
      response.body
      |> Floki.find(".product-details table tbody tr :nth-child(2)")
      # default to empty string if not found
      |> Enum.at(1, "")
      |> Floki.text()
      |> String.trim()

    images =
      response.body
      |> Floki.find("label.thumb img")
      |> Floki.attribute("src")

    # Save images
    images |> Enum.each(fn img_url -> save_image(brand, img_url) end)

    %Crawly.ParsedItem{
      :items => [
        %{
          id: id,
          title: title,
          brand: brand,
          images: images
        }
      ],
      :requests => requests
    }
  end

  defp build_absolute_url(url) do
    URI.merge(base_url(), url) |> to_string()
  end

  def save_image("", _), do: :ignored

  def save_image(brand, img_url) do
    brand = brand |> String.downcase() |> String.replace(" ", "_")

    base_dir = "#{File.cwd!()}/tmp/sarenza/#{brand}"
    File.mkdir_p(base_dir)

    case HTTPoison.get(img_url) do
      {:ok, response} -> save_jpeg(base_dir, response.body)
      _ -> Logger.error("Failed to fetch image...")
    end
  end

  # defp save_jpeg(dir, buffer) do
  #   case ExMagic.from_buffer!(buffer) do
  #     "image/jpeg" ->
  #       filename = "#{UUID.uuid4()}.jpeg"
  #       full_path = Path.join(dir, filename)
  #       File.write(full_path, buffer)

  #     _ ->
  #       Logger.error("Image is not a JPEG...")
  #   end

  defp save_jpeg(dir, buffer) do
    filename = "#{UUID.uuid4()}.jpeg"
    full_path = Path.join(dir, filename)

    File.write(full_path, buffer)
  end
end
