using a public EC2 with elastiuc ip



# tools needed

- nginx
- git
- cert-bot # this will give me ssl certs


# check user data logs
```bash
# Main log - user-data output + cloud-init logs combined
sudo cat /var/log/cloud-init-output.log

# Just cloud-init's own process log (more verbose, less focused on your script output)
sudo cat /var/log/cloud-init.log
```

```bash
git clone https://github.com/akhileshmishrabiz/july-devops/
cp july-devops/week2/hosting-portfolio/portfolio.html .
sudo ls /usr/share/nginx/html/index.html 
sudo cp portfolio.html /usr/share/nginx/html/index.html 
sudo systemctl reload nginx

```


```bash
sudo certbot --nginx -d mansipandey.in 
```

# /var/log/letsencrypt/letsencrypt.log
<!-- Certificate is saved at: /etc/letsencrypt/live/mansipandey.in/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/mansipandey.in/privkey.pem -->


sudo cp portfolio.html /usr/share/nginx/html/index.html 