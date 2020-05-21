defmodule YaqTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Yaq

  describe "Yaq constructor" do
    test "calling new/0 produces an empty queue" do
      q = Yaq.new()
      assert q.l_size() == 0
      assert q.r_size() == 0
      assert q.l_data() == []
      assert q.r_data() == []
    end

    property "calling new/1 produces a queue fetchulated with list data" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)
        assert q.l_size() == length(input)
        assert q.r_size() == 0
        assert q.l_data() == input
        assert q.r_data() == []
      end
    end
  end

  describe "Yaq I/O operations" do
    property "convert queue to list" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)
        assert Yaq.to_list(q) == input
      end
    end

    property "enqueue data produces a queue fetchulated with list data" do
      check all(input <- list_of(term())) do
        q = Enum.reduce(input, Yaq.new(), fn x, acc -> Yaq.enqueue(acc, x) end)
        assert Yaq.to_list(q) == input
      end
    end

    property "enqueue_r data produces a queue fetchulated with reversed list data" do
      check all(input <- list_of(term())) do
        q = Enum.reduce(input, Yaq.new(), fn x, acc -> Yaq.enqueue_r(acc, x) end)
        assert Yaq.to_list(q) == Enum.reverse(input)
      end
    end

    test "dequeue, dequeue_r from an empty queue returns an {nil, empty_queue}" do
      q = Yaq.new()

      {nil, ^q} = Yaq.dequeue(q)
      {nil, ^q} = Yaq.dequeue_r(q)
      {:my_atom, ^q} = Yaq.dequeue(q, :my_atom)
      {:your_atom, ^q} = Yaq.dequeue(q, :your_atom)
    end

    property "dequeue data produces data in the order it was inserted" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)

        {result, final_q} =
          Enum.reduce(
            input,
            {[], q},
            fn _x, {data, queue} ->
              {value, new_queue} = Yaq.dequeue(queue)
              {[value | data], new_queue}
            end
          )

        assert Enum.reverse(result) == input
        assert Yaq.size(final_q) == 0
      end
    end

    property "dequeue_r data produces data in the reverse order it was inserted" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)

        {result, final_q} =
          Enum.reduce(
            input,
            {[], q},
            fn _x, {data, queue} ->
              {value, new_queue} = Yaq.dequeue_r(queue)
              {[value | data], new_queue}
            end
          )

        assert Enum.reverse(result) == Enum.reverse(input)
        assert Yaq.size(final_q) == 0
      end
    end

    property "peek/1 shows the front of the list" do
      check all(input <- list_of(term())) do
        q = Enum.reduce(input, Yaq.new(), fn x, acc -> Yaq.enqueue(acc, x) end)
        assert Yaq.peek(q) == List.first(input)
      end
    end

    property "peek_r/1 shows the back of the list" do
      check all(input <- list_of(term())) do
        q = Enum.reduce(input, Yaq.new(), fn x, acc -> Yaq.enqueue(acc, x) end)
        assert Yaq.peek_r(q) == List.last(input)
      end
    end

    test "fetch/1 returns `:error` when queue is empty" do
      q = Yaq.new()
      assert Yaq.fetch(q) == :error
    end

    test "fetch_r/1 returns `:error` when queue is empty" do
      q = Yaq.new()
      assert Yaq.fetch_r(q) == :error
    end

    test "fetch!/1 raises Yaq.EmptyQueueError when queue is empty" do
      q = Yaq.new()
      assert_raise Yaq.EmptyQueueError, fn -> Yaq.fetch!(q) end
    end

    test "fetch_r!/1 raises Yaq.EmptyQueueError when queue is empty" do
      q = Yaq.new()
      assert_raise Yaq.EmptyQueueError, fn -> Yaq.fetch_r!(q) end
    end

    property "concat/2 appends to the end of a queue" do
      check all(
              input <- list_of(term()),
              addenda <- list_of(term())
            ) do
        q = Yaq.new(input) |> Yaq.concat(addenda)
        assert Yaq.to_list(q) == input ++ addenda
      end
    end

    property "concat_r/2 prepends to the front of a queue" do
      check all(
              input <- list_of(term()),
              addenda <- list_of(term())
            ) do
        q = Yaq.new(input) |> Yaq.concat_r(addenda)
        assert Yaq.to_list(q) == addenda ++ input
      end
    end

    property "size/1 counts the number of elements in the queue" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)
        assert Yaq.size(q) == length(input)
      end
    end
  end

  describe "Inspect protocol" do
    property "inspect string shows the length of the queue" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)
        assert "#Yaq<length: #{length(input)}>" == "#{inspect(q)}"
      end
    end
  end

  describe "Enumerable protocol" do
    property "Enum.count/1 is the same as Yaq.size/1" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)

        assert Enum.count(q) == Yaq.size(q)
      end
    end

    property "Enum.member?/2 can find element from Yaq" do
      check all(
              input <- list_of(term()),
              length(input) > 0,
              value <- StreamData.constant(Enum.random(input))
            ) do
        q = Yaq.new(input)

        assert Enum.member?(q, value)
      end
    end

    property "Enum.map/1 will return the input list" do
      check all(input <- list_of(term())) do
        q = Yaq.new(input)
        same_list = Enum.map(q, & &1)

        assert same_list == input
      end
    end
  end

  describe "Collectable protocol" do
    property "we can iterate into a list" do
      check all(input <- list_of(term())) do
        q = Enum.into(input, Yaq.new())
        output = Yaq.to_list(q)

        assert input == output
      end
    end
  end
end
