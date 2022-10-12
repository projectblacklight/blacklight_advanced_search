describe "NestingParser" do
  describe "Consuming" do
    before do
      @parser = ParsingNesting::Grammar.new
    end
    # Whole bunch of things we just want to make sure they are consumed
    # without error, not checking the generated tree yet.
    ["foo",
     "foo bar",
     " foo bar ",
     " foo bar   baz    ",
     "+foo",
     "-foo",
     "+foo -bar",
     "one +two three -four five",
     "foo AND bar",
     "one AND two AND three AND four",
     "one OR two OR three OR four",
     "white OR blue AND big OR small",
     "+yes AND book OR -online",
     "(one AND two)",
     "  (  one   AND     two     )  ",
     "(one OR two) three +four",
     "(one AND two) OR three",
     "(one AND -two) AND (+three OR (-four AND five))",
     "one two three NOT four",
     "one two three NOT (four OR five)",
     "NOT four",
     "NOT (four five)",
     "(one two three) OR (four five) AND six",
     '"foo+bar (baz"',
     "(foo bar one AND two) AND (three four ten OR twelve)",
     "one () two"
    ].each do |query|
      it "should consume<<#{query}>>" do
        expect { @parser.parse(query) }.not_to raise_error
      end
    end
  end
end
