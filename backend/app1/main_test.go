package main

import (
	"testing"

	"golang.org/x/example/hello/reverse"
)

func TestStr(t *testing.T) {
	if reverse.String("Hello world!") != str() {
		t.Errorf("string not reversed")
	}
}
