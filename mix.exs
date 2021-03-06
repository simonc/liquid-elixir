defmodule Liquid.Mixfile do
  use Mix.Project

  def project do
    [ app: :liquid,
      version: "0.1.0",
      elixir: "~> 1.0",
      deps: deps,
      name: "Liquid",
      description: description,
      package: package,
      source_url: "https://github.com/nulian/liquid-elixir"]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:credo, "~> 0.2", only: [:dev, :test]}]
  end

  defp description do
    """
    Liquid implementation in elixir
    """
  end

  defp package do
    [
      files: ["lib", "README*", "mix.exs"],
      maintainers: ["Peter Arentsen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nulian/liquid-elixir"}
    ]
  end
end
