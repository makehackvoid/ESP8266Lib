file.open("pass","w");
file.writeline("eyal");
file.writeline("my_password");
file.close();


file.open("pass","r");
print (file.read());
file.close();
