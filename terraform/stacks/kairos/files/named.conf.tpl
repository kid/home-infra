# vim: set ft=named noexpandtab ts=4 sw=4:

acl internal {
	localnets;
	10.0.5.3/32;
	10.0.100.0/24;
};

options {
    directory "/var/bind";

    // Specify a list of CIDR masks which should be allowed to issue recursive
    // queries to the DNS server. Do NOT specify 0.0.0.0/0 here; see above.
    allow-recursion {
		//"internal";
		any;
    };

    // If you want this resolver to itself resolve via means of another recursive
    // resolver, uncomment this block and specify the IP addresses of the desired
    // upstream resolvers.
    forwarders {
          1.1.1.1;
          1.0.0.1;
          9.9.9.9;
    };

    // By default the resolver will attempt to perform recursive resolution itself
    // if the forwarders are unavailable. If you want this resolver to fail outright
    // if the upstream resolvers are unavailable, uncomment this directive.
    //forward only;

    // Configure the IPs to listen on here.
    listen-on { any; };
    listen-on-v6 { none; };

    version "no";

    dnssec-validation auto;

    // If you have problems and are behind a firewall:
    //query-source address * port 53;

    //pid-file "/var/run/named/named.pid";

    //query-log yes;

    // Removing this block will cause BIND to revert to its default behaviour
    // of allowing zone transfers to any host (!). There is no need to allow zone
    // transfers when operating as a recursive resolver.
    //allow-transfer { none; };
    //allow-query-cache { localhost; localnets; };

    //response-policy {
	//	zone "rpz.local" max-policy-ttl 1h;
	//} break-dnssec yes;
};

%{for k, v in tsig_keys}
key "${k}" {
	algorithm ${v.algorithm};
	secret "${v.secret}";
};
%{endfor}

view "internal" {
	match-clients { internal; };
	allow-recursion { any; };
	recursion yes;
	zone "kidibox.net" {
		type master;
		file "/etc/bind/db.kidibox.net.internal";
		journal "/etc/bind/journals/db.kidibox.net.internal.jnl";
		update-policy {
%{for k, v in tsig_keys}
			grant ${k} zonesub any;
%{endfor}
		};
	};
};

view "external" {
	match-clients { any; };
	recursion no;
	zone "kidibox.net" {
		type forward;
		forwarders { 1.1.1.1; 1.0.0.1; 9.9.9.9; };
	};
};
