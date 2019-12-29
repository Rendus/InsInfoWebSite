<?php
  #phpinfo();
  require(dirname(__FILE__).'/data.php');
?>

<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>My Test Website</title>
    <link rel="stylesheet" type="text/css" href="StyleSheet.css">
    <style>
      #MyContents {background: <?php echo $H1_Colour; ?>;}
      #header{background-color: <?php if($H1_Colour == "white") echo "yellowgreen"; else echo "white"; ?>;}
    </style>
	</head>
	<body>
		<img src="https://previews.123rf.com/images/apostrophe/apostrophe1604/apostrophe160400050/56269936-abstract-silver-gray-background-white-center-darker-border-with-sponge-vintage-grunge-background-tex.jpg" class="bg">
		<div id="MyContents">
			<h1>
				<div id="header"><center>My Hello World Website</center></div>
			</h1>
			<br>
      <h2>
        <center>
          <p>Server Info:</p>
          <table class="minimalistBlack">
            <thead>
              <tr>
                <th>Type</th>
                <th>Data</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Instance ID</td>
                <td><?php echo $InsID; ?></td>
              </tr>
              <tr>
                <td>Container Host Name</td>
                <td><?php echo $Host; ?></td>
              </tr>
              <tr>
                <td>Container IP Address</td>
                <td><?php echo $ContainerIP; ?></td>
              </tr>
              <tr>
                <td>Instance Public IP</td>
                <td><?php echo $InsIP; ?></td>
              </tr>
              <tr>
                <td>Instance Private IP</td>
                <td><?php echo $InspIP; ?></td>
              </tr>
              <tr>
                <td>Client IP Address</td>
                <td><?php echo getRealClientIpAddr(); ?></td>
              </tr>
              <tr>
                <td>Current Time (UTC)</td>
                <td><?php $t=time(); echo date("Y-m-d H:i:s", $t); ?></td>
              </tr>
              <tr>
                <td>Website Visit Count (Cache)</td>
                <td><?php echo $Count1; ?></td>
              </tr>
              <tr>
                <td>Client Visited (DB)</td>
                <td><?php echo $DBClientData; ?></td>
              </tr>
              <tr>
                <td>Instance Visited (DB)</td>
                <td><?php echo $DBInspData; ?></td>
              </tr>
              <tr>
                <td>Container Visited (DB)</td>
                <td><?php echo $DBHostData; ?></td>
              </tr>
            </tbody>
          </table>
        </center>
      </h2>
			<h3>
				<center>Image 1</center>
			</h3>
			<center>
				<a href="https://image.slidesharecdn.com/devopsonaws-acceleratingsoftwaredelivery-170629005251/95/devops-on-aws-accelerating-software-delivery-11-638.jpg"  target="_blank">
					<img src="https://image.slidesharecdn.com/devopsonaws-acceleratingsoftwaredelivery-170629005251/95/devops-on-aws-accelerating-software-delivery-11-638.jpg" alt="screen-shot1" title="screen-shot1">
				</a>
			</center>
			<br>
			<h3>
				<center>Image 2</center>
			</h3>
			<center>
				<a href="https://image.slidesharecdn.com/devopsonaws-deepdiveandawsdevtools-160505154738/95/devops-on-aws-3-638.jpg"  target="_blank">
					<img src="https://image.slidesharecdn.com/devopsonaws-deepdiveandawsdevtools-160505154738/95/devops-on-aws-3-638.jpg" alt="screen-shot1" title="screen-shot2">
				</a>
			</center>
			<br>
			<h3>
				<center>Image 3</center>
			</h3>
			<center>
				<a href="https://image.slidesharecdn.com/2017-03-28-loft-devops-intro-170328202927/95/introduction-to-devops-and-the-aws-code-services-12-638.jpg"  target="_blank">
					<img src="https://image.slidesharecdn.com/2017-03-28-loft-devops-intro-170328202927/95/introduction-to-devops-and-the-aws-code-services-12-638.jpg" alt="screen-shot1" title="screen-shot3">
				</a>
			</center>
		</div>
	</body>
</html>

<!--
# https://www.goodbytes.be/blog/article/docker-a-simple-example-for-a-php-mysql-setup

Dockerfile Commands:
====================
# apt-get update && apt-get -y install gcc make autoconf libc-dev pkg-config

FROM php:7.2-apache
RUN echo '' | pecl install -o -f redis && rm -rf /tmp/pear && docker-php-ext-enable redis
RUN docker-php-ext-install pdo pdo_mysql mysqli
RUN echo "extension=redis.so" > $(php -i 2>/dev/null| grep 'php.ini' | awk '{print $NF}')/conf.d/redis.ini
RUN echo 'extension=mysqli.so' > $(php -i 2>/dev/null| grep 'php.ini' | awk '{print $NF}')/conf.d/mysqli.ini
COPY . /var/www/html
====================

ENVIRONMENT VARIABLES NEEDED:
=============================
variables   => DefaultValue
~~~~~~~~~~~~~~~~~~~~~~~~~~~
EC_ENDPOINT => redis
EC_PORT     => 6379
DB_ENDPOINT => mysql-db
DB_USERNAME => mysql-db
DB_PASSWORD => Password_at_123
DB_PORT     => 3306
DB_NAME     => website_visit_record
COLOUR      => white

# Create Mysql Table Schema:
CREATE DATABASE website_visit_record;
USE website_visit_record;
CREATE TABLE IF NOT EXISTS client_visit_details (seq INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY, client_ip VARCHAR(255) NOT NULL, host_ip VARCHAR(255) NOT NULL, container VARCHAR(255) NOT NULL, vist_count INT, last_visit DATETIME);
-->
