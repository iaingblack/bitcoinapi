export ARM_CLIENT_SECRET=Add_Secret_Here
export ARM_ACCESS_KEY=Add_Key_Here

task init    ENV=testing
task plan    ENV=testing VARFILE=dev
task apply   ENV=testing VARFILE=dev
task destroy ENV=testing VARFILE=dev
task sensitive-output
task clean