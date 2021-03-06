defmodule Liquid.Parse do
  alias Liquid.Template, as: Template
  alias Liquid.Variable, as: Variable
  alias Liquid.Registers, as: Registers
  alias Liquid.Block

  def tokenize(<<string::binary>>) do
    Regex.split(Liquid.template_parser, string, on: :all_but_first, trim: true)
      |> List.flatten
      |> Enum.filter(&(&1 != ""))
  end

  def parse(<<string::binary>>, %Template{}=template) do
    tokens = tokenize(string)
    [name|_] = tokens
    tag_name = parse_tag_name(name)
    tokens = parse_tokens(string, tag_name) || tokens
    { root, template } = parse(%Liquid.Block{name: :document}, tokens, [], template)
    %{ template | root: root }
  end

  defp parse_tokens(<<string::binary>>, tag_name) do
    case Registers.lookup(tag_name) do
      {mod, Liquid.Block} ->
        try do
          mod.tokenize(string)
        rescue
          UndefinedFunctionError ->
        end
      _ ->
    end
  end

  defp parse_tag_name(name) do
    case Regex.named_captures(Liquid.parser, name) do
      %{"tag" => tag_name, "variable" => _ } -> tag_name
      _ ->
    end
  end

  defp parse_node(<<name::binary>>, rest, %Template{}=template) do
    case Regex.named_captures(Liquid.parser, name) do
      %{"tag" => "", "variable" => <<markup::binary>>} ->
        { Variable.create(markup), rest, template }
      %{"tag" => <<markup::binary>>, "variable" => ""} ->
        [name|_] = String.split(markup, " ")
        case Registers.lookup(name) do
          { mod, Liquid.Block } ->

            block = Liquid.Block.create(markup)
            { block, rest, template } = try do
                mod.parse(block, rest, [], template)
              rescue
                UndefinedFunctionError -> parse(block, rest, [], template)
              end
            { block, template } = mod.parse(block, template)
            { block, rest, template }
          { mod, Liquid.Tag } ->
            tag = Liquid.Tag.create(markup)
            { tag, template } = mod.parse(tag, template)
            { tag, rest, template }
          nil -> raise "unregistered tag: #{name}"
        end
      nil -> { name, rest, template }
    end
  end

  def parse(%Block{name: :document}=block, [], accum, %Template{}=template) do
    { %{ block | nodelist: accum }, template }
  end

  def parse(%Block{name: name}, [], _, _) do
    raise "No matching end for block {% #{to_string(name)} %}"
  end

  def parse(%Block{name: name}=block, [h|t], accum, %Template{}=template) do

    endblock = "end" <> to_string(name)
    cond do
      Regex.match?(~r/{%\s*#{endblock}\s*%}/, h) ->
        { %{ block | nodelist: accum }, t, template }
      Regex.match?(~r/{%\send.*?\s*$}/, h) ->
        raise "Unmatched block close: #{h}"
      true ->
        { result, rest, template } = parse_node(h, t, template)
        parse(block, rest, accum ++ [result], template)
    end
  end
end
