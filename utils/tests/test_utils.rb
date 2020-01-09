def assert_equal_many(items)
    first_item = items[0]
    for item in items.drop(1)
        assert_equal(first_item, item)
    end
end