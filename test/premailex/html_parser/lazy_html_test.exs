defmodule Premailex.HTMLParser.LazyHTMLTest do
  use ExUnit.Case

  alias Premailex.HTMLParser.LazyHTML

  describe "filter/2" do
    test "with identical nodes with broad tag match" do
      tree =
        LazyHTML.parse("""
        <div>
          <p>
            <span class="same">Same</span>
            <span class="same">Same</span>
          </p>
          <span class="same">Same</span>
        </div>
        """)

      assert LazyHTML.to_string(LazyHTML.filter(tree, "span")) ==
               """
               <div>
                 <p>
                 </p>
               </div>
               """
    end

    test "with identical nodes with first of type match" do
      tree =
        LazyHTML.parse("""
        <div>
          <p>
            <span class="same">Same</span>
            <span class="same">Same</span>
          </p>
          <span class="same">Same</span>
        </div>
        """)

      assert LazyHTML.to_string(LazyHTML.filter(tree, "span:first-of-type")) ==
               """
               <div>
                 <p>
                   <span class="same">Same</span>
                 </p>
               </div>
               """
    end

    test "with identical nodes with child selector" do
      tree =
        LazyHTML.parse("""
        <div>
          <p>
            <span class="same">Same</span>
            <span class="same">Same</span>
          </p>
          <span class="same">Same</span>
        </div>
        """)

      assert LazyHTML.to_string(LazyHTML.filter(tree, "p > span:last-of-type")) ==
               """
               <div>
                 <p>
                   <span class="same">Same</span>
                 </p>
                 <span class="same">Same</span>
               </div>
               """
    end

    test "with whitespace text node before filtered node" do
      tree =
        LazyHTML.parse("""
        <div>   <span>Remove</span></div>
        """)

      assert LazyHTML.to_string(LazyHTML.filter(tree, "span")) == """
             <div>   </div>
             """
    end

    test "with tag node before filtered node" do
      tree =
        LazyHTML.parse("""
        <div><p>Keep</p><span>Remove</span></div>
        """)

      assert LazyHTML.to_string(LazyHTML.filter(tree, "span")) == """
             <div><p>Keep</p></div>
             """
    end
  end
end
