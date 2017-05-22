# Export Polar Data to GPX and Runkeeper

## About

This is a command line tool that will log in to your [polarpersonaltrainer.com](https://polarpersonaltrainer.com) account and let you export all, or some, of your workouts in GPX format.

The tool also allows for exporting directly to [RunKeeper](https://runkeeper.com). It will attempt to resolve and sync only Polar activities that do not already exist on Runkeeper, attempting to avoid duplicates if possible.


## General Usage

### Login

`./ppt2rk --email you@emailaddress.com --password yourpolarpassword`

or

`./ppt2rk -e you@emailaddress.com -p yourpolarpassword`


For an interactive password prompt, omit the `-p` flag:

`./ppt2rk -e you@emailaddress.com`



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


## Runkeeper Usage

### Login

`./ppt2rk --download runkeeper --email you@emailaddress.com --password yourpolarpassword --rkemail you@emailaddress.com --rkpassword yourrunkeeperpassword`

or

`./ppt2rk -d runkeeper -e you@emailaddress.com -p yourpolarpassword -rke you@emailaddress.com -rkp yourrunkeeperpassword`


For an interactive password prompt, omit the `-p` flag:

`./ppt2rk -d runkeeper -e you@emailaddress.com -rke you@emailaddress.com`

The tool then operates in `sync` download mode (see below for more info on download modes), but will also upload GPX files to Runkeeper.


### Other Options

#### Download

Use the `--download` or `-d` flag to bypass the user prompt. This flag supports the following options:

`all` downloads all GPX files.

`last` downloads the most recent GPX file.

`lastX` downloads the *X* most recent GPX files, where *X* is an integer greater than zero.

`first` downloads the first GPX file in the list.

`firstX` downloads the first *X* GPX files, where *X* is an integer greater than zero.

`sync` keeps track of downloaded workouts and only downloads new GPX files as they become available.

`runkeeper` performs the same operation as `sync`, but will also create new activites on the Runkeeper site, using the GPX files downloaded from Polar.


#### Keychain

Email and password can be persisted to the Keychain on macOS, using the `--keychain` or `-k` flag.

To save an email and password to the keychain:

`./ppt2rk -e you@emailaddress.com -p yourpolarpassword -k`

This also works for Runkeeper credentials:

`./ppt2rk -e you@emailaddress.com -p yourpolarpassword -rke you@emailaddress.com -rkp yourrunkeeperpassword -k`


Subsequent use of the app can drop the credential parameters and the saved details will be used:

`./ppt2rk -k`


#### Reset

Used to reset the list of workout IDs used by the `--download sync` command. Use `--reset` or `-r` and the list will be cleared before login/download is executed.

