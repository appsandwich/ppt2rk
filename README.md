# Export Polar Data to GPX

## About

This is a command line tool that will log in to your [polarpersonaltrainer.com] account and let you export all, or some, of your workouts in GPX format.

The end goal with this project is to eventually allow exporting directly to RunKeeper. So far, only the Polar to GPX export functionality has been implemented.


## Usage

### Login

`./ppt2rk -e you@emailaddress.com -p yourpolarpassword`

The app will log in to your account and download the full list of workouts, similar to the following:

```
Logging in as you@emailaddress.com...
Getting workouts from 1970-01-01T00:00:00.000 to 2017-05-12T11:55:01.065. This may take some time...
***********************************************************
5 workouts found. Pick one to export to GPX.
[Index]    Workout ID       Timestamp
[1]        246351671        2014-02-16T11:10:41.000
[2]        246351701        2014-02-16T11:10:43.000
[3]        247109471        2014-02-17T19:54:05.000
[4]        252516155        2014-03-03T09:05:32.000
[5]        253317431        2014-03-05T08:43:58.000


5 workouts found. Pick one to export to GPX.
***********************************************************
To download a single file, enter a value from 1 to 5, then hit Return.
To download multiple files, enter values separated by space or comma (e.g. 1,2,3,4,5) then hit Return.
To download all files, enter 0 then hit Return.
Or, hit Return to quit.

```

### Download GPX

* To download a single file, enter a value from 1 to 5, then hit Return.
* To download multiple files, enter values separated by space or comma (e.g. 1,2,3,4,5) then hit Return.
* To download all files, enter 0 then hit Return.
* Or, hit Return to quit.

Downloaded GPX files are saved to `~/Library/Caches/ppt2rk/WORKOUTID.gpx`.
