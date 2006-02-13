#! /usr/bin/env slsh
_debug_info = 1;

if (__argc < 2)
{
   () = fprintf (stderr, "Usage: %s files....\n", __argv[0]);
   exit (1);
}

static variable Data;

static define init ()
{
   Data = Assoc_Type[String_Type];
}

static define warning ()
{
   variable args = __pop_args (_NARGS);
   () = fprintf (stderr, "***WARNING: %s\n", sprintf (__push_args ()));
}

		 
static define process_function (line, fp)
{
   variable fname;
   variable lines;

   fname = strtrim (strtok (line, "{}")[1]);
   
   lines = line;
#iftrue
   foreach (fp)
     {
	line = ();
	lines = strcat (lines, line);
	if (0 == strncmp ("\\done", line, 5))
	  break;
     }
#else
   while (-1 != fgets (&line, fp))
     {
	lines += line;
	if (0 == strncmp ("\\done", line, 5))
	  break;
     }
#endif
   if (assoc_key_exists (Data, fname))
     {
	warning ("Key %s already exists", fname);
	return -1;
     }
   
   Data[fname] = lines;
   return 0;
}

static define process_variable (line, fp)
{
   % warning ("process_variable not implemented");
   process_function (line, fp);
}

static define read_file_contents (file)
{
   variable fp = fopen (file, "r");
   variable n = 0;
   variable line;

   if (fp == NULL)
     {
	() = fprintf (stderr, "Unable to open %s\n", file);
	return -1;
     }
   

   %while (-1 != fgets (&line, fp))
   foreach (fp)
     {
	line = ();
	if (0 == strncmp (line, "\\function{", 10))
	  {
	     if (-1 == process_function (line, fp))
	       return -1;
	     
	     continue;
	  }
	
	if (0 == strncmp (line, "\\variable{", 10))
	  {
	     if (-1 == process_variable (line, fp))
	       return -1;
	     
	     continue;
	  }
     }
   
   () = fclose (fp);
   return 0;
}

static define sort_and_write_file_elements (file)
{
   variable fp;
   variable i, keys;
   variable backup_file;

   backup_file = file + ".BAK";
   () = remove (backup_file);
   () = rename (file, backup_file);

   fp = fopen (file, "w");
   if (fp == NULL)
     return -1;

   keys = assoc_get_keys (Data);
   i = array_sort (keys, &strcmp);
   
   foreach (keys[i])
     {
	variable k = ();

	() = fputs (Data[k], fp);
	() = fputs ("\n", fp);
     }
   
   () = fclose (fp);
   
   return 0;
}


static define process_file (file)
{
   init ();
   
   () = fprintf (stdout, "Processing %s ...", file);
   () = fflush (stdout);

   if (-1 == read_file_contents (file))
     return -1;
   
   if (-1 == sort_and_write_file_elements (file))
     return -1;

   () = fputs ("done.\n", stdout);
   return 0;
}

foreach (__argv[[1:]])
  process_file ();

exit (0);
