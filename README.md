# Lapis REST API

Very simple REST API created in the Lapis framework for the university class. \
API is persisting changes in the .txt files -
is not connected to the database.

## How to run

Type `lapis server` in the terminal. API should be available at the default 8080 port.

## Quick docs

### Products

`GET /products` - returns the list of products. \
`GET /products/{productId}` - returns the details of the specified product.\
`POST /products` - creates a new product, example:

    {
        "name": "Milk",
        "price": 3.99,
        "category_id": 1
    }

`PUT /products/{productId}` - modifies the specified product. \
`DELETE /products/{productId}` - deletes the specified product.

### Categories

`GET /categories` - returns the list of categories. \
`GET /categories/{categoryId}` - returns the details of the specified category.\
`POST /categories` - creates a new category, example:

    {
        "name": "Dairy",
    }

`PUT /categories/{categoryId}` - modifies the specified category. \
`DELETE /categories/{categoryId}` - deletes the specified category.

**Author: Przemysław Kocur**
