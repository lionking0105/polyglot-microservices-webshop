package main

type Cart struct {
	UserID string     `json:"userId"`
	Items  []CartItem `json:"cartItems"`
}

type CartItem struct {
	ProductID string `json:"productId"`
	Quantity  int    `json:"quantity"`
	Price     int    `json:"price"`
}
