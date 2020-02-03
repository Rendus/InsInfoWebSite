<?php
  require(dirname(__FILE__).'/MyFunctions.php');

  $Host = gethostname();
  $ContainerIP = getenv('SERVER_ADDR');

  $ClientIP = getRealClientIpAddr();
  $InsID = cURL("http://169.254.169.254/latest/meta-data/instance-id");
  $InsIP = cURL("http://169.254.169.254/latest/meta-data/public-ipv4");
  $InspIP = cURL("http://169.254.169.254/latest/meta-data/local-ipv4");

  $H1_Colour = getenv('COLOUR');
  if (empty($H1_Colour))
    $H1_Colour = 'white';

  # Rdis
  try{
    $EndPoint = getenv("EC_ENDPOINT");
    if (empty($EndPoint))
      $EndPoint = "redis"; # Set default value
    $RedisPort = getenv("EC_PORT");
    if (empty($RedisPort))
      $RedisPort = "6379";
    $RedisConnectioTimeout = 1;
    $Key1 = $ClientIP;
    $redis = getConnection($EndPoint, $RedisPort, $RedisConnectioTimeout);
    if ($redis) {
      if ($redis->exists($Key1)) {
        $tmp = $redis->get($Key1);
        $redis->set($Key1, $tmp + 1);
        $Count1 = $tmp + 1;
      } else {
        $redis->set($Key1, 1);
        $Count1 = 1;
      }
    } else {
      $Count1 = 'Error connecting to Redis!!';
    }
  }
  catch(\Throwable $e) {
    $Count1 = "Unknow ERROR occured while communicating with Redis.";
  }

  # DataBase
  try{
    $DBHost = getenv("DB_ENDPOINT");
    $DBusername = getenv("DB_USERNAME");
    $DBpassword = getenv("DB_PASSWORD");
    $DBname = getenv("DB_NAME");
    $DBPort = getenv("DB_PORT");
    if (empty($DBHost))
      $DBHost = "mysql-db";
    if (empty($DBusername))
      $DBusername = "root";
    if (empty($DBpassword))
      $DBpassword = "Password_at_123";
    if (empty($DBname))
      $DBname = "website_visit_record";
    if (empty($DBPort))
      $DBPort = 3306;

    $DBData = NULL;
    $Connection = mysqli_init();
    mysqli_options($Connection, MYSQLI_OPT_CONNECT_TIMEOUT, 4);
    mysqli_options($Connection, MYSQLI_OPT_READ_TIMEOUT, 5);
    $Connection->real_connect($DBHost, $DBusername, $DBpassword, $DBname, $DBPort);
    if($Connection->connect_error) {
      $DBData = "Error - " . $Connection->connect_error;
      $DBClientData = $DBData;
      $DBInspData = $DBData;
      $DBHostData = $DBData;
    } else {
      $Query = 'SELECT vist_count FROM client_visit_details WHERE client_ip = "'.$ClientIP.'" AND host_ip = "'.$InspIP.'" AND container = "'.$Host.'";';
      $Result = mysqli_query($Connection, $Query);
      if (mysqli_num_rows($Result) <= 0) {
        $Query = 'INSERT INTO client_visit_details (client_ip, host_ip, container, vist_count, last_visit) VALUES ("'.$ClientIP.'", "'.$InspIP.'", "'.$Host.'", 1, NOW());';
        if (!mysqli_query($Connection, $Query)) {
          $DBData = "Erro Inserting data to DB!";
        }
      } else {
        $Count = mysqli_fetch_array($Result)[0]+1;
        $Query = 'UPDATE client_visit_details SET vist_count = ' .strval($Count).', last_visit = NOW() WHERE client_ip = "'.$ClientIP.'" AND host_ip = "'.$InspIP.'" AND container = "'.$Host.'";';
        if (!mysqli_query($Connection, $Query)) {
          $DBData = "Error Updating data to DB!";
        }
      }
      $Query = 'SELECT SUM(vist_count) FROM client_visit_details WHERE client_ip = "'.$ClientIP.'";';
      $DBClientData = mysqli_fetch_array(mysqli_query($Connection, $Query))[0] or $DBClientData = "Couldn't query Client Data!";
      $Query = 'SELECT SUM(vist_count) FROM client_visit_details WHERE host_ip = "'.$InspIP.'";';
      $DBInspData = mysqli_fetch_array(mysqli_query($Connection, $Query))[0] or $DBInspData = "Couldn't query Instance Data!";
      $Query = 'SELECT SUM(vist_count) FROM client_visit_details WHERE container = "'.$Host.'";';
      $DBHostData = mysqli_fetch_array(mysqli_query($Connection, $Query))[0] or $DBHostData = "Couldn't query Host Data!";
    }
  }
  catch(\Throwable $e){
    $DBClientData = "Unknow ERROR occured while communicating with MySQL.";
    $DBInspData = $DBClientData;
    $DBHostData = $DBClientData;
  }
?>
