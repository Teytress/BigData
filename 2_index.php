<?php
include "predis/autoload.php";
$siteName=$_SERVER['SERVER_ADDR'];
$protocol="http://";
$html="<html><body>";
$html.="<title>URL Shortener</title>";
$html.="<h3>URL Shortener</h3>";

Predis\Autoloader::register();
try {$redis=new Predis\Client();}
catch(Exception $e){$html.="PredisLoadingError:".$e->getMessage();}
//если установлен параметр "s", содержащий короткое имя - переадресуем на полную ссылку
if(!empty($_GET["s"])){
	$shortName=$_GET["s"];
	$data=$redis->hgetall($shortName);
	$redis->hincrby($shortName, "counter",1);
	$html.=$data["url"];
	header("Location: ".$data["url"]);
}
//если была нажата кнопка отправки формы - добавляем в базу новое короткое имя, если его ещё нет
if(isset($_POST["shortButton"])){
	$shortName=$_POST["ShortName"];
	$url=$_POST["URL"];
	if($redis->exists($shortName)) $html.="Short name \"".$shortName."\" already exists!";
	else{
		$redis->hmset($shortName, ['url'=>$url, 'counter'=>0]);
		$redis->expire($shortName, 7*24*60*60);
		$shortLink=$protocol.$siteName."/?s=".$shortName;
		$html.="Short URL: <a href=\"".$shortLink."\">".$shortLink."</a>";
	}
}
//главная форма
$html.="<form action=\"index.php\" name=\"mainForm\", method=\"post\">";
$html.="<p>Short name:<br><input type=\"text\", ".
"name=\"ShortName\" placeholder=\"cats\"></p>";
$html.="<p>URL:<br><textarea name=\"URL\" placeholder=\"".
"https://www.pinterest.ru/pin/376261743866615679/\"></textarea></p>";
$html.="<p><input name=\"shortButton\", type=submit value=\"GetShort\"></p>";
$html.="</form></body></html>";
echo $html;
?>
