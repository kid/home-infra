package main

import (
	_ "github.com/coredns/alternate"
	"github.com/coredns/coredns/core/dnsserver"
	_ "github.com/coredns/coredns/core/plugin"
	"github.com/coredns/coredns/coremain"
)

func init() {
	dnsserver.Directives = append(dnsserver.Directives, "alternate")
}

func main() {
	coremain.Run()
}
