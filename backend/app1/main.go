package main

import (
	"fmt"

	"golang.org/x/example/hello/reverse"
)

func str() string {
	return reverse.String("Hello world!")
}

func main() {
	fmt.Println(str())
}
