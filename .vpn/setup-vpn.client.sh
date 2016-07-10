. vpn.txt

apt-get install strongswan xl2tpd

#cp vpnca.cert.pem /usr/share/ca-certificates
#dpkg-reconfigure ca-certificates

cp vpnclient.key.pem /etc/ipsec.d/private/
cp vpnca.cert.pem /etc/ipsec.d/cacert/
cp vpnclient.cert.pem /etc/ipsec.d/cert/

echo <<EOF

conn vpnconn
      leftsubnet=192.168.0.0/16
      leftcert=vpnclient.cert.der
      right=$serverip
      rightsubnet=192.168.0.0/16
      rightid="$serverdn"
      auto=start

EOF

