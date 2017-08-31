# jsonapi_spec_helpers

This gem provides a number of low-level helpers as well as an abstraction for asserting entire payloads.

## Low-level helpers

* `json`: Parsed JSON from the response represented as a ruby hash.
* `json_item`: Typically used for `show` actions, this grabs the relevant attributes from the response and merges with `id` and `type`. `type` is renamed `jsonapi_type` so it does not conflict with a `type` attribute.
* `json_items`: Like `json_item` but for `index` actions. Pass indices to grab specific items, e.g. `json_items(0,1)`.
* `json_related_link`: Assert the payload has a `link` for the given relation, e.g. `expect(json_related_link(json_item, 'people').to eq('/people/1')`
* `json_included_types`: A unique array of all `type`s in the `included` response.
* `json_includes(type, *indicies)`: Grab from `included` and transform into a `json_item`, e.g. `json_includes('people')`.
* `json_include(type, index = 0)`: Same as `json_includes` but returns a single element instead of an array.
* `json_ids`: An array of all ids in `json_items`. Pass `json_ids(true)` to return all integers.
* `validation_errors`: A hash of validation errors, e.g. `{ name: "can't be blank" }`

## assert_payload

In JSONAPI responses, the same object payload can be repeated across many different responses. So, instead of asserting on the response itself, you can assert the response contains a given payload. Start by defining your payloads:

```ruby
JsonapiSpecHelpers::Payload.register(:person) do
  key(:name)
  key(:age)
end
```

And then assert on them in specs:

```ruby
person = Person.last
# Pass:
# * registered payload name
# * a record to compare against
# * a json_item
assert_payload(:person, person, json_include('people'))
```

This asserts:

* All registered keys have correct values (compared to given record)
* No registered keys are missing
* No extra keys are present in the response

It's the rough code equivalent of:

```ruby
person = Person.last
json = JSON.parse(response.body)
included = json['included'].find { |incl| incl['type'] == 'people' }
expect(included).to have_key('name')
expect(included['name']).to eq(person.name)
expect(included).to have_key('age')
expect(included['age']).to eq(person.age)
expect(included.keys).to match_array(%w(name age))
```

### Custom Payloads

Let's say your serializer always capitalizes `name`. In this case, the above `assert_record_payload` would fail. To make it pass, supply a block to the `key` argument:

```ruby
JsonapiSpecHelpers::Payload.register(:person) do
  key(:name) { |record| record.name.upcase }
  key(:age)
end
```

The test will now pass, as we've registered a custom response comparison.

You can customize payloads at assertion-time as well. Let's say you only want to render `age` if the current user is an admin. A spec could look something like:

```ruby
sign_in(:admin)
get :show, id: person.id
assert_payload(:person, person, json_item)
sign_in(:non_admin)
get :show, id: person.id
assert_payload(:person, person, json_item) do
  no_key(:age)
end
```

The `no_key` method overrides the default `age` key and specifies this key should not be present in the response. Any keys specified in this block will override the defaults.

## Request helpers

It's recommended to use `jsonapi_get`, `jsonapi_post`, etc instead of the corresponding rspec methods. This way we ensure `jsonapi_headers` are always passed, and can be overridden. Let's say we want to add a JWT to our request headers:

```ruby
def jsonapi_headers
  headers = super
  headers['X-JWT'] = jwt
  headers
end

let(:jwt) { "s0m3t0k3n" }

let(:payload) do
  {
    data: {
      type: 'employees',
      attributes: { name: 'John Doe' }
    }
  }
end

it "works correctly" do
  jsonapi_post("/api/v1/employees", payload)
  # assert on response
end
```

* `jsonapi_get(url, params)`
* `jsonapi_post(url, payload)`
* `jsonapi_put(url, payload)`
* `jsonapi_delete(url)`
