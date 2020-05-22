defmodule Yaq.MixProject do
  use Mix.Project

  def project do
    [
      app: :yaq,
      version: "1.2.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stream_data, "~> 0.5.0", only: :test},
      {:ex_doc, "~> 0.22.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      name: "Yaq",
      source_url: "https://github.com/NullOranje/yaq",
      extras: ["README.md"]
    ]
  end

  defp package() do
    [
      description: "Double-ended queue rewritten for Elixir",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/NullOranje/yaq"}
    ]
  end
end
