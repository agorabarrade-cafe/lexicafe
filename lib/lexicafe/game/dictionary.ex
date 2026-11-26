defmodule Lexicafe.Game.Dictionary do
  @moduledoc """
  Diccionario local del juego (palabras normalizadas a mayúsculas).

  El paquete Docker instala el léxico ampliado a partir de un listado de
  frecuencia en español CC BY 4.0. Fuera de Docker, ejecutar primero
  `python3 scripts/build_dictionary.py`. La lista demo es solo un respaldo.

  Las vocales con tilde se igualan, pero N y Ñ son letras distintas.
  Este léxico no constituye un diccionario normativo de Scrabble.
  """

  @key {__MODULE__, :words}

  def normalized(word) when is_binary(word) do
    word
    |> String.upcase()
    |> String.replace("Á", "A")
    |> String.replace("É", "E")
    |> String.replace("Í", "I")
    |> String.replace("Ó", "O")
    |> String.replace("Ú", "U")
    |> String.replace("Ü", "U")
  end

  def valid?(word) when is_binary(word), do: MapSet.member?(words(), normalized(word))
  def size, do: MapSet.size(words())

  def source do
    if File.exists?(Path.join(:code.priv_dir(:lexicafe) |> to_string(), "dictionary/es_lexicafe_extended.txt")) do
      :extended
    else
      :demo
    end
  end

  defp words do
    case :persistent_term.get(@key, nil) do
      nil ->
        set = load_words()
        :persistent_term.put(@key, set)
        set
      set -> set
    end
  end

  defp load_words do
    priv = :code.priv_dir(:lexicafe) |> to_string()
    extended = Path.join(priv, "dictionary/es_lexicafe_extended.txt")
    demo = Path.join(priv, "dictionary/es_mx_demo.txt")
    path = if File.exists?(extended), do: extended, else: demo

    path
    |> File.stream!([], :line)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Stream.flat_map(&String.split/1)
    |> Stream.map(&normalized/1)
    |> MapSet.new()
  end
end
