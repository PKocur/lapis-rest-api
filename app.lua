json = require("cjson")
local lapis = require("lapis")
local app = lapis.Application()
local respond_to = require("lapis.application").respond_to
local json_params = require("lapis.application").json_params

function save_products()
    save("product_data.txt", products)
end

function read_products()
    return read("product_data.txt")
end

function save_categories()
    save("category_data.txt", categories)
end

function read_categories()
    return read("category_data.txt")
end

function save(filename, collection)
    local file = assert(io.open(filename, "w"))
    result = json.encode(collection)
    result = result:gsub("null,", "")
    file:write(result)
    file:close()
end

function read(filename)
    local file = io.open(filename, "r")
    local content = file:read("*a")
    local table = json.decode(content)
    file:close()
    return table
end

function save_sequences()
    local file = assert(io.open("sequences.txt", "w"))
    result = products_sequence .. "," .. categories_sequence
    file:write(result)
    file:close()
end

function read_sequences()
    local file = io.open("sequences.txt", "r")
    local content = file:read("*a")
    local products_sequence, categories_sequence = content:match("([^,]+),([^,]+)")
    file:close()
    return products_sequence, categories_sequence
end

products_sequence, categories_sequence = read_sequences()
products = read_products()
categories = read_categories()

product = {}
function product:create_put(id, name, price, category_id)
    local this = {
        id = id,
        name = name,
        price = price,
        categoryId = category_id
    }
    return this
end
function product:create(name, price, category_id)
    products_sequence = products_sequence + 1
    local this = {
        id = products_sequence,
        name = name,
        price = price,
        categoryId = category_id
    }
    table.insert(products, this)
    save_products()
    save_sequences()
    return this
end

category = {}
function category:create_put(id, name)
    local this = {
        id = id,
        name = name
    }
    return this
end
function category:create_post(name)
    categories_sequence = categories_sequence + 1
    local this = {
        id = categories_sequence,
        name = name
    }
    table.insert(categories, this)
    save_categories()
    save_sequences()
    return this
end

function error_field_required(field_name)
    return { json = { error = "Field '" .. field_name .. "' is required" }, status = 400 }
end

function error_category_not_exists(category_id)
    return { json = { error = "Category of id '" .. category_id .. "' does not exist" }, status = 400 }
end

function error_category_used(category_id)
    return { json = { error = "Category of id '" .. category_id .. "' is used by products" }, status = 400 }
end

function category_exists(category_id)
    if category_id < 1 then
        return false
    end
    if get_category(category_id) == nil then
        return false
    else
        return true
    end
end

function is_category_used(category_id)
    if category_id < 1 then
        return false
    end
    for key, value in pairs(products) do
        if value.categoryId == category_id then
            return true
        end
    end
    return false
end

function get_product(id)
    return get_model_by_id(id, products)
end

function get_category(id)
    return get_model_by_id(id, categories)
end

function get_model_by_id(id, collection)
    for key, value in pairs(collection) do
        if value.id == id then
            return value
        end
    end
    return nil
end

function get_collection_index_of_model(id, collection)
    for key, value in pairs(collection) do
        if value.id == id then
            return key
        end
    end
    return nil
end

app:match("products", "/products", respond_to({
    GET = function(self)
        return { json = { results = products } }
    end,
    POST = json_params(function(self)
        if self.params.name == nil then
            return error_field_required("name", self.params.name)
        end
        if self.params.price == nil then
            return error_field_required("price", self.params.price)
        end
        if self.params.category_id == nil then
            return error_field_required("category_id", self.params.category_id)
        elseif not category_exists(self.params.category_id) then
            return error_category_not_exists(self.params.category_id)
        end
        product:create(self.params.name, self.params.price, self.params.category_id)
        return { json = {}, status = 201 }
    end)
}))

app:match("product", "/products/:productId", respond_to({
    GET = function(self)
        return { json = { get_product(tonumber(self.params.productId)) } }
    end,
    PUT = json_params(function(self)
        if self.params.name == nil then
            return error_field_required("name", self.params.name)
        end
        if self.params.price == nil then
            return error_field_required("price", self.params.price)
        end
        if self.params.category_id == nil then
            return error_field_required("category_id", self.params.category_id)
        elseif not category_exists(self.params.category_id) then
            return error_category_not_exists(self.params.category_id)
        end
        local product_id = tonumber(self.params.productId)
        local index = get_collection_index_of_model(product_id, products)
        if index == nil then
            return { json = {}, status = 400 }
        end
        products[index] = product:create_put(product_id, self.params.name, self.params.price, self.params.category_id)
        save_products()
        return { json = {}, status = 204 }
    end),
    DELETE = function(self)
        local index = get_collection_index_of_model(tonumber(self.params.productId), products)
        if index == nil then
            return { json = {}, status = 202 }
        end
        products[index] = nil
        save_products()
        return { json = {}, status = 202 }
    end

}))

app:match("categories", "/categories", respond_to({
    GET = function(self)
        return { json = { results = categories } }
    end,
    POST = json_params(function(self)
        if self.params.name == nil then
            return error_field_required("name", self.params.name)
        end
        category:create_post(self.params.name)
        return { json = {}, status = 201 }
    end)
}))

app:match("category", "/categories/:categoryId", respond_to({
    GET = function(self)
        return { json = { get_category(tonumber(self.params.categoryId)) } }
    end,
    PUT = json_params(function(self)
        if self.params.name == nil then
            return error_field_required("name", self.params.name)
        end
        local category_id = tonumber(self.params.categoryId)
        local index = get_collection_index_of_model(category_id, categories)
        if index == nil then
            return { json = {}, status = 400 }
        end
        categories[index] = category:create_put(category_id, self.params.name)
        save_categories()
        return { json = {}, status = 204 }
    end),
    DELETE = function(self)
        local category_id = tonumber(self.params.categoryId)
        if is_category_used(category_id) then
            return error_category_used(category_id)
        end
        local index = get_collection_index_of_model(category_id, categories)
        if index == nil then
            return { json = {}, status = 202 }
        end
        categories[index] = nil
        save_categories()
        return { json = {}, status = 202 }
    end
}))

return app
