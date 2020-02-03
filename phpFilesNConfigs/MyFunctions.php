<?php
# Common Functions
  function cURL($url){
    try{
      $curl = curl_init();
      curl_setopt_array($curl, [
        CURLOPT_RETURNTRANSFER => 1,
        CURLOPT_URL => $url,
        CURLOPT_USERAGENT => "cURL"
      ]);
      $data = curl_exec($curl);
      curl_close($curl);
      if(empty($data)){
        $data = "Couldn't get data from URL: " . $url;
      }
    }
    catch(\Throwable $e) {
      $data = $e->getMessage();
    }
    return $data;
  }

  function getConnection($ip, $port, $timeout) {
    try {
      $r = new Redis();
      if ($r->connect($ip, $port, $timeout)) {
        $r->ping();
        return $r;
      } else {
        return false;
      }
    } catch (RedisException $ex) {
        return false;
    }
  }

  function getRealClientIpAddr()
  {
    if (!empty($_SERVER['HTTP_X_FORWARDED_FOR']))   //to check ip is passed from proxy
    {
      $ip=$_SERVER['HTTP_X_FORWARDED_FOR'];
    }
    elseif (!empty($_SERVER['HTTP_CLIENT_IP']))
    {
      $ip=$_SERVER['HTTP_CLIENT_IP'];
    }
    else
    {
      $ip=$_SERVER['REMOTE_ADDR'];
    }
    return $ip;
  }
?>
