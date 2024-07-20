//Importing necessary libraries
//Importing firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
//Import flutter necessities
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//Import other pages
import 'package:fbla_2023/save_and_open_pdf.dart';
import 'package:fbla_2023/consts.dart';
//Import AI
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
//Import GNav Bar
import 'package:google_nav_bar/google_nav_bar.dart';

final db = FirebaseFirestore.instance; //Variable for firebase
String email = ""; //String that stores user's email for firebase
int userSemesters = 0; //Variable for the user's total semesters
int honors = 0; //Variable for the user's total honors semesters
int ap = 0; //Variable for the user's total AP semesterse
List<String> grades = []; //List that stores all the user's grades
List<String> gpaScale = []; //List that stores all the gpa additions
List<String> classType = []; //List that stores the types of classes
double weightedGPA = 0;
double unweightedGPA = 0;
bool reg = false; //Used to track sign up vs. sign in

//Main function that runs the whole program through firebase login
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp()); //Runs the MainApp class which runs the entire App
}

//MainApp class which runs the app, starting with the homepage
class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  //Widget that runs the app starting with the homepage
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, //Turning off the debug banner
        home: Auth()); // Set the starting page to Auth
  }
}

//Help Screen is the screen that contains the instructions and button to access AI
//It also includes what the app grades off of, and how it correlates to prompt
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  Help createState() => Help();
}

//Creates a class for the help page of the app
class Help extends State<HelpScreen> {
  // index of page
  int currentIndex = 0;
  void signUserOut() {
    if (email != "") {
      //Sending all of the user's data (if it exists) to firebase
      final send = {
        'Number of Semesters': userSemesters,
        'Unweighted GPA': unweightedGPA,
        'Weighted GPA': weightedGPA,
        'Grades': grades,
        'Semester Types': classType,
      };
      // Stores the data with the doc name as the users email
      db.collection("users").doc(email).set(send);
    }
    FirebaseAuth.instance.signOut(); //Signs out the user
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const Auth())); // Sends them to the auth page
  }

  @override
  //Creates the build of the page
  Widget build(BuildContext context) {
    return Container(
      //Sets background color
      color: const Color(0xff0A1930),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          //Creates floating action button to send to AIPage
          floatingActionButton: FloatingActionButton(
            //Sets background color of button
            backgroundColor: const Color(0xff7FAEFF),
            onPressed: () {
              //Sends them to the AIPage to chat with Grade Gemini
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AIPage()));
            },
            // White icon with sparkles logo to represent Gemini/AI
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Colors.white,
            ),
          ),
          //Centers everything within it on the app
          body: SingleChildScrollView(
            child: Center(
                child: Column(
              children: [
                const Padding(padding: EdgeInsets.all(20)),
                Row(children: [
                  const Padding(padding: EdgeInsets.only(left: 160)),
                  //Heading of page
                  const Text('Help',
                      style: TextStyle(fontSize: 40, color: Colors.white)),
                  const Padding(padding: EdgeInsets.only(left: 60)),
                  //Button that signs users out and is in the same row as heading
                  IconButton(
                      onPressed: signUserOut,
                      icon: const Icon(Icons.logout,
                          color: Color(0xffC0C0C0), size: 30))
                ]),
                //Creates a box on the screen to space out the container
                const SizedBox(
                  height: 25,
                  width: 300,
                ),

                //Creates the container that contains the help text
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xff0A1930), //Creating the box's color
                    borderRadius: BorderRadius.circular(25), //Curving the edges
                    border: Border.all(
                        color: const Color.fromARGB(221, 190, 183, 183),
                        width: 3.0), //Creating a border for the box
                  ),

                  //Creating the text and its padding for the contatiner
                  padding: const EdgeInsets.all(25),
                  //Text containing the instructions for how to use the app
                  //And its correlations
                  child: const Text(
                      "Welcome to Grade Point:\nThis calculator correlates to the FBLA Prompt for Intro to Programming, as it can calculate both weighted and unweighted GPAs off of a user's grades and is based on the North Creek High School grading scale.\n\nThe following grading scale is used for our app:\nA   (93% - 100%+) --- 4.0\nA-  (90% - 92.9%) --- 3.7\nB+ (87% - 89.9%) --- 3.3\nB   (83% - 86.9%) --- 3.0\nB-  (80% - 82.9%) --- 2.7\nC+ (77% - 79.9%) --- 2.3\nC   (73% - 76.9%) --- 2.0\nC-  (70% - 72.9%) --- 1.7\nD+ (67% - 69.9%) --- 1.3\nD   (60% - 66.9%) --- 1.0\nF   (40% - 59.9%) --- 0.0\n\n(For AP Classes 1.0 is added to GPA for that class and for Honors it is 0.5)\n\nThere are 4 pages in this app, the first one is just the classes. The second one is the help screen where you can get instructions. The third is acessible from the second and is a chatBot that provides personzalized help for users. Finally, the last page will display the GPAs and a report of all your grades. \n \n To calculate your GPA, navigate to the middle button on the screen, and click the plus button to add your classes. A new container will be generated every time you click this button. Fill this container's dropdowns with the grade that you earned in the semester of a class, and the type of class that it is in the second dropdown. You can calculate your GPA once you have filled out all of the fields on this page, and click the confirm button. \n \n You will be redirected to the report screen, where you can see your weighted and unweighted GPAs, as well as a comprehensive report of each of your classes, the grade you earned, and the effect that it has on your overall GPA. If you click the light blue download button in the bottom right of the screen, you will be redirected to a page that generates a PDF of the report. \n \n If you have any additional questions, you can go to the help page to get them answered, and click the light blue button at the bottom if you want to chat with the chatbot about navigating the app, learning about the purpose of the app, and more! ",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                //Adding padding to space things out
                const Padding(
                  padding: EdgeInsets.all(25),
                ),
              ],
            )),
          ),
          //Creates container that bottomNavBar is created in
          bottomNavigationBar: Container(
              color: Colors.black,
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 20), // Padding for better spacing
                  //Creating the GNav
                  child: GNav(
                      //Setting the index to the index of the page
                      selectedIndex: currentIndex,
                      backgroundColor: Colors.black, //Setting background color to black
                      duration: const Duration(milliseconds: 1000), // Increasing duration for cleaner animation
                      color: Colors.white, // Setting color of icons
                      activeColor: Colors.white,
                      tabBackgroundColor: Colors.grey.shade800, //Setting background of selected button
                      gap: 8,
                      padding: const EdgeInsets.all(16),
                      tabs: [
                        GButton(
                            icon: Icons.help,
                            text: 'Help',
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HelpScreen()));
                            }),
                        GButton(
                          icon: Icons.check_circle,
                          text: 'Classes',
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MainPage()));
                          },
                        ),
                        GButton(
                            icon: Icons.list,
                            text: 'Report',
                            onPressed: () {
                              bool cont = true;
                              for (int i = 0; i < userSemesters; i++) {
                                if (grades[i] == "" || classType[i] == "") {
                                  cont = false;
                                }
                              }
                              if (cont) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const NewMainPage()));
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MainPage()));
                              }
                            }),
                      ])))),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  Page3 createState() => Page3();
}

//Creates a page for the page where the user inputs all of their grades as percentages
class Page3 extends State<MainPage> {
  int currentIndex = 1;
  int ind = 1;
  int counter = 0;
  bool proceed = false;
  List<String> array = [];

  void signUserOut() {
    if (email != "") {
      //Sending all of the user's data (if it exists) to firebase
      final send = {
        'Number of Semesters': userSemesters,
        'Unweighted GPA': unweightedGPA,
        'Weighted GPA': weightedGPA,
        'Grades': grades,
        'Semester Types': classType,
      };
      // Stores the data with the doc name as the users email
      db.collection("users").doc(email).set(send);
    }
    FirebaseAuth.instance.signOut(); //Signs out the user
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const Auth())); // Sends them to the auth page
  }

  @override
  //Creates the build of the page
  Widget build(BuildContext context) {
    if (grades.length < userSemesters) {
      for (int i = classType.length; i <= userSemesters; i++) {
        grades.add("");
      }
    }
    if (classType.length < userSemesters) {
      for (int i = classType.length; i <= userSemesters; i++) {
        classType.add("");
      }
    }

    //Creates the main part of the page
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              userSemesters++;
            });
          },
          backgroundColor: const Color(0xff7FAEFF),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            const Color(0xff0A1930), //Sets the background color for the page

        //Main part of the page
        body: Material(
            //Makes page scrollable
            child: SingleChildScrollView(
                child: Container(
          color: const Color(0xff0A1930), //Set background
          child: Column(children: [
            const Padding(padding: EdgeInsets.all(20)),
            Row(children: [
              const Padding(padding: EdgeInsets.only(left: 120)), //Adding spacing
              const Text('Classes',
                  style: TextStyle(fontSize: 40, color: Colors.white)), //Header of page
              const Padding(padding: EdgeInsets.only(left: 40)), //Adding spacing
              //Clickable button to sign user out
              IconButton(
                  onPressed: signUserOut,
                  icon: const Icon(Icons.logout,
                      color: Color(0xffC0C0C0), size: 30))
            ]),
            //Container for the whole page
            Container(
                color: const Color(0xff0A1930),
                //Creates the container that contains the list
                child: Column(

                    //Code that updates the page in case the user changes values
                    children: [
                      Form(
                        autovalidateMode: AutovalidateMode.always,
                        onChanged: () {
                          setState(() {
                            Form.of(primaryFocus!.context!).save();
                          });
                        },
                        //Creates the list using the number of semesters the user inputted in
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            userSemesters, //Number of boxes to create
                            (int index) {
                              return Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(20.0),
                                    decoration: BoxDecoration(
                                        color: const Color(
                                            0xff0c142c), //Creates the color for the container
                                        borderRadius: BorderRadius.circular(20), //Curve edges for better look
                                        border: Border.all(
                                            color: const Color(0xffC0C0C0)) //Change color of the border
                                        ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 110)),
                                            const Text("Grade Earned: ",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 40)),
                                            // Icon to delete the class box
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                setState(() {
                                                  //Bring the values above the deleted one down
                                                  for (int j = index;
                                                      j < userSemesters - 1;
                                                      j++) {
                                                    grades[j] = grades[j + 1];
                                                    classType[j] =
                                                        classType[j + 1];
                                                  }
                                                  //Decrement semesters to delete a box
                                                  //Delete extra values after the user semesters amount
                                                  userSemesters--;
                                                  for (int c = userSemesters;
                                                      c < grades.length;
                                                      c++) {
                                                    grades[c] = "";
                                                    classType[c] = "";
                                                  }
                                                });
                                              },
                                              color: const Color(0xffC0C0C0),
                                            )
                                          ],
                                        ),
                                        // Creates dropdown to pick the grade
                                        DropdownButton(
                                          hint: grades[index] == ""
                                              // Set blank text as Select
                                              ? const Text('Select',
                                                  style: TextStyle(
                                                      color: Colors.white))
                                              // If not blank set it as chosen grade
                                              : Text(
                                                  grades[index],
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                          isExpanded: true,
                                          iconSize: 30.0,
                                          style: const TextStyle(
                                              color: Color(0xff4A3B8C)),
                                          items: [
                                            'A (93% - 100%+)',
                                            'A- (90% - 92.9%)',
                                            'B+ (87% - 89.9%)',
                                            'B (83% - 86.9%)',
                                            'B- (80% - 82.9%)',
                                            'C+ (77% - 79.9%)',
                                            'C (73% - 76.9%)',
                                            'C- (70% - 72.9%)',
                                            'D+ (67% - 69.9%)',
                                            'D (60% - 66.9%)',
                                            'F (0% - 59.9%)'
                                          ].map(
                                            (value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            },
                                          ).toList(),
                                          onChanged: (value) {
                                            setState(
                                              () {
                                                grades[index] =
                                                    value.toString();
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 15),
                                        const Text("Class Type: ",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        //Create dropdown to pick type of class
                                        DropdownButton(
                                          hint: classType[index] == ""
                                              //Display text if nothing is selected
                                              ? const Text('Select',
                                                  style: TextStyle(
                                                      color: Colors.white))
                                              //Display text if dropdown is selected
                                              : Text(
                                                  classType[index],
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                          isExpanded: true, //Make it expandable
                                          iconSize: 30.0, //Size of icon
                                          style: const TextStyle(
                                              color: Color(0xff4A3B8C)),
                                          //Items that are choosable
                                          items:
                                              ['Regular', 'Honors', 'AP'].map(
                                            (val) {
                                              return DropdownMenuItem<String>(
                                                value: val,
                                                child: Text(val),
                                              );
                                            },
                                          ).toList(),
                                          onChanged: (val) {
                                            setState(
                                              () {
                                                classType[index] =
                                                    val.toString();
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ));
                            },
                          ),
                        ),
                      ),
                      //Only let show the next page button if userSemesters isn't 0
                      if (userSemesters != 0)
                        //Create button to go to next page
                        MaterialButton(
                            onPressed: () {
                              bool cont = true;
                              //Check through all values for empty ones
                              for (int i = 0; i < userSemesters; i++) {
                                if (grades[i] == "" || classType[i] == "") {
                                  cont = false; //If empty set value to false
                                }
                              }
                              //Send to the report page if not empty
                              if (cont) {
                                Navigator.of(context).pop('Update');
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const NewMainPage()));
                              }
                            },
                            color: const Color(0xff4A3B8C), //Set color of button
                            child: const Text('Confirm',
                                style: TextStyle(color: Colors.white))),
                      const Padding(padding: EdgeInsets.all(20))//Space button out
                    ]))
          ]),
        ))),
        //Create bottomNavBar
        bottomNavigationBar: Container(
            color: Colors.black,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                //Use the imported GNav Bar
                child: GNav(
                    duration: const Duration(milliseconds: 1000),
                    selectedIndex: currentIndex,
                    backgroundColor: Colors.black,
                    color: Colors.white,
                    activeColor: Colors.white,
                    tabBackgroundColor: Colors.grey.shade800,
                    gap: 8,
                    padding: const EdgeInsets.all(16),
                    //Create tabs that switch to the 3 different main pages
                    tabs: [
                      GButton(
                          icon: Icons.help,
                          text: 'Help',
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const HelpScreen()));
                          }),
                      GButton(
                        icon: Icons.check_circle,
                        text: 'Classes',
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainPage()));
                        },
                      ),
                      GButton(
                          icon: Icons.list,
                          text: 'Report',
                          onPressed: () {
                            bool cont = true;
                            for (int i = 0; i < userSemesters; i++) {
                              if (grades[i] == "" || classType[i] == "") {
                                cont = false;
                              }
                            }
                            //If all boxes are filled in continue on
                            if (cont) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NewMainPage()));
                            //If they aren't stay on page
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const MainPage()));
                            }
                          }),
                    ]))));
  }
}

class NewMainPage extends StatefulWidget {
  const NewMainPage({super.key});
  @override
  Page4 createState() => Page4();
}

//Creates the final page that does all the calculations and displayas the users GPAs
class Page4 extends State<NewMainPage> {
  //Adding needed variables
  int currentIndex = 2;
  int percent = 0;
  double total = 0.0;
  double total2 = 0.0;
  double average = 0.0;
  double average2 = 0.0;
  int numGrades = 0;

  List<String> gpaScale = [];
  List<String> displayGrades = [];

  //Method to sign the user out using firebase
  void signUserOut() {
    if (email != "") {
      //Sending all of the user's data (if it exists) to firebase
      final send = {
        'Number of Semesters': userSemesters,
        'Unweighted GPA': unweightedGPA,
        'Weighted GPA': weightedGPA,
        'Grades': grades,
        'Semester Types': classType,
      };
      // Stores the data with the doc name as the users email
      db.collection("users").doc(email).set(send);
    }
    FirebaseAuth.instance.signOut(); //Signs out the user
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const Auth())); // Sends them to the auth page
  }

  @override
  Widget build(BuildContext context) {
    //Does all the math for the grades and adds them to the gpaScale
    setState(() {
      for (int i = 0; i < userSemesters; i++) {
        if (grades[i] != "") {
          numGrades++;
          if (grades[i] == 'A (93% - 100%+)') {
            gpaScale.add('4.0');
          } else if (grades[i] == 'A- (90% - 92.9%)') {
            gpaScale.add('3.7');
          } else if (grades[i] == 'B+ (87% - 89.9%)') {
            gpaScale.add('3.3');
          } else if (grades[i] == 'B (83% - 86.9%)') {
            gpaScale.add('3.0');
          } else if (grades[i] == 'B- (80% - 82.9%)') {
            gpaScale.add('2.7');
          } else if (grades[i] == 'C+ (77% - 79.9%)') {
            gpaScale.add('2.3');
          } else if (grades[i] == 'C (73% - 76.9%)') {
            gpaScale.add('2.0');
          } else if (grades[i] == 'C- (70% - 72.9%)') {
            gpaScale.add('1.7');
          } else if (grades[i] == 'D+ (67% - 69.9%)') {
            gpaScale.add('1.3');
          } else if (grades[i] == 'D (60% - 66.9%)') {
            gpaScale.add('1.0');
          } else {
            gpaScale.add('0');
          }
        }
      }

      //Going through the list and adding all the values to the total GPA
      if (gpaScale.isNotEmpty) {
        total = 0;
        for (int j = 0; j < gpaScale.length; j++) {
          total += double.parse(gpaScale[j]);
        }
      }
      //Reset them before adding on
      ap = 0;
      honors = 0;
      for (int i = 0; i < classType.length; i++) {
        if (classType[i] == 'Honors') {
          honors++;
        }
        if (classType[i] == 'AP') {
          ap++;
        }
      }

      //Creating the two averages for unweighted and weighted GPAs
      //Do this by dividing the total by number of semesters
      total2 = total;
      total2 += ap;
      total2 += honors / 2;
      if (userSemesters != 0) {
        average = total / userSemesters;
        average2 = total2 / userSemesters;
      }
      //Add 0s as place holders to increase length
      unweightedGPA = average;
      String transform = unweightedGPA.toString();
      while (transform.length < 5) {
        transform += "0";
      }

      unweightedGPA =
          double.parse(transform.substring(0, transform.indexOf('.') + 3));
      weightedGPA = average2;
      transform = weightedGPA.toString();
      while (transform.length < 5) {
        transform += "0";
      }
      //Conver it back to a double
      weightedGPA =
          double.parse(transform.substring(0, transform.indexOf('.') + 3));
      //Create the list that displays the values
      for (int i = 1; i <= userSemesters; i++) {
        //Check if values are blank
        if (grades[i - 1] != "") {
          String gradeValue = grades[i - 1];
          //Change value based on + or -
          if (gradeValue.contains('+') || gradeValue.contains('-')) {
            gradeValue = gradeValue.substring(0, 2);
          } else {
            gradeValue = gradeValue.substring(0, 1);
          }
          //Create new variables to use in creation of display list
          String gpaValue = gpaScale[i - 1];
          String type = classType[i - 1];
          double newVal = 0;
          //Figure out weightedGPA points
          if (type == 'Honors') {
            newVal += 0.5;
          } else if (type == "AP") {
            newVal += 1;
          }
          //Add unweighted gpa to extra points for weightedGPA
          //Add version with parenthesis if it isn't a regular class
          newVal += double.parse(gpaValue);
          if (type == 'Honors' || type == 'AP') {
            displayGrades
                .add("Sem $i: $gradeValue ($type) --> $gpaValue ($newVal)");
          //Add with no extra parenthesis at the end if regular class
          } else {
            displayGrades.add("Sem $i: $gradeValue ($type) --> $gpaValue");
          }
        }
      }

      //Resetting the values of total so that the grades don't keep multiplying
    });
    //Creates the page
    return Container(
      color: const Color(0xff0A1930),
      child: Scaffold(
          backgroundColor:
              Colors.transparent, //Background color on the main page
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final simplePdfFile = await SimplePdfApi.generateSimpleTextPdf(
                  email, '$unweightedGPA', '$weightedGPA', displayGrades);
              SaveAndOpenDocument.openPDF(simplePdfFile);
            },
            backgroundColor: const Color(0xff7FAEFF),
            child: const Icon(
              Icons.file_download,
              color: Colors.white,
            ),
          ),

          //Creates the appbar at the top of the screen
          //The main part of the page
          body: SingleChildScrollView(
            child: Center(
                child: Column(children: [
              const Padding(padding: EdgeInsets.all(20)),
              Row(children: [
                const Padding(padding: EdgeInsets.only(left: 130)),
                const Text('Report',
                    style: TextStyle(fontSize: 40, color: Colors.white)),
                const Padding(padding: EdgeInsets.only(left: 50)),
                IconButton(
                    onPressed: signUserOut,
                    icon: const Icon(Icons.logout,
                        color: Color(0xffC0C0C0), size: 30))
              ]),

              //Creates a box for spacing
              const SizedBox(
                height: 20,
                width: 300,
              ),

              //Creates the container that displays the unweighted GPA
              Container(
                  height: 100,
                  width: 300,
                  decoration: BoxDecoration(
                      color: const Color(
                          0xff0c142c), //Changes the color of the container
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xffC0C0C0)) //Curves the edges
                      ),

                  //Creates the text and padding
                  child: Center(
                    child: Row(children: [
                      const Padding(padding: EdgeInsets.only(left: 30)),
                      const Text(
                        'Unweighted GPA: ',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      Text('$unweightedGPA',
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white))
                    ]),
                  )),

              //Creates a box for spacing
              const SizedBox(
                height: 20,
                width: 300,
              ),

              //Creates a container that displays the users weighted GPA
              Container(
                  height: 100,
                  width: 300,
                  decoration: BoxDecoration(
                      color: const Color(
                          0xff0c142c), //Creates the color for the container
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(
                              0xffC0C0C0)) //Curves the edges//Creates the border
                      ),

                  //Creates the text and its padding
                  child: Center(
                    child: Row(
                      children: [
                        const Padding(padding: EdgeInsets.only(left: 37)),
                        const Text(
                          'Weighted GPA: ',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Text(
                          '$weightedGPA',
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(
                height: 20,
                width: 300,
              ),
              //If user semestrs isn't 0 create the grade report container
              if (userSemesters != 0)
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                      color: const Color(
                          0xff0c142c), //Creates the color for the container
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(
                              0xffC0C0C0)) //Curves the edges//Creates the border
                      ),
                  padding: const EdgeInsets.all(20), //Create padding at edges
                  child: Column(children: [
                    //Create the grade report display
                    const Text(
                      'Grade Report',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    const Text('', style: TextStyle(fontSize: 10)),
                    //Convert the list of displayables grades into the column as text
                    Column(
                      children: displayGrades
                          .map((value) => Text(value,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 17)))
                          .toList(),
                    ),
                  ]),
                ),
              const Padding(
                padding: EdgeInsets.all(15),
              ),
              //Edit button that sends you back to edit your responses
              MaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainPage()));
                  },
                  color:
                      const Color(0xff4A3B8C), //Changes the color of the button
                  child: const Text('Edit',
                      style: TextStyle(color: Colors.white))),
              const Padding(padding: EdgeInsets.all(5)),
            ])),
          ),
          //Create bottomNavBar
          bottomNavigationBar: Container(
              color: Colors.black,
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 20),
                  //Create the imported GNav Bar
                  child: GNav(
                      //Create duration for smoother transition
                      duration: const Duration(milliseconds: 1000),
                      //Set to current tab for page
                      selectedIndex: currentIndex,
                      backgroundColor: Colors.black,
                      color: Colors.white,
                      activeColor: Colors.white,
                      tabBackgroundColor: Colors.grey.shade800,
                      gap: 8,
                      padding: const EdgeInsets.all(16),
                      //Create the tabs for the main pages
                      tabs: [
                        GButton(
                            icon: Icons.help,
                            text: 'Help',
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HelpScreen()));
                            }),
                        GButton(
                          icon: Icons.check_circle,
                          text: 'Classes',
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MainPage()));
                          },
                        ),
                        const GButton(
                          icon: Icons.list,
                          text: 'Report',
                        ),
                      ])))),
    );
  }
}
//Login page the logs in the user based on firebase
class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Creates the login page for the user to get into their account
class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // This method signs the user in using their email and password
  // It only lets them through if it finds and account with the credentials
  void signUserIn() async {
    email = usernameController.text;
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text, password: passwordController.text);
    reg = false;
    final docRef = db.collection("users").doc(email);
    docRef.get().then(
      // Takes info from the firebase then stores it in the programs variables
      (DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        userSemesters = data["Number of Semesters"];
        unweightedGPA = data["Unweighted GPA"];
        weightedGPA = data["Weighted GPA"];
        honors = data["Honors Semesters"];
        ap = data["AP Semesters"];
        grades = List.from(data['Grades']);
        classType = List.from(data['Semester Types']);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff0c142c), //Creates background color
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        height: 300,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('assets/images/Logo.png')))),//Takes the image from assets and uses it
                    Container(
                      decoration: const BoxDecoration(
                          color: Color(0xfff1f4f8),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(60),
                              topRight: Radius.circular(60))),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          // logo
                          const Icon(
                            Icons.lock,
                            size: 100,
                          ),
                          // welcome back
                          const Text("Welcome back!",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              )),
                          const SizedBox(height: 25),
                          // username textfield
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: TextField(
                              controller: usernameController,
                              obscureText: false,
                              decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade400),
                                  ),
                                  fillColor: Colors.grey.shade200,
                                  filled: true,
                                  hintText: "Email",
                                  hintStyle:
                                      TextStyle(color: Colors.grey[500])),
                            ),
                          ),

                          const SizedBox(height: 25),
                          // password textfield
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade400),
                                  ),
                                  fillColor: Colors.grey.shade200,
                                  filled: true,
                                  hintText: "Password",
                                  hintStyle:
                                      TextStyle(color: Colors.grey[500])),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // sign in button
                          // Check for tap
                          GestureDetector(
                            onTap: signUserIn,
                            child: Container(
                                padding: const EdgeInsets.all(25),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Center(
                                  child: Text(
                                    "Sign In",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                )),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(25),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Not a member?',
                                      style: TextStyle(color: Colors.black)),
                                  const SizedBox(width: 4),
                                  //Check for tap
                                  GestureDetector(
                                    onTap: widget.onTap,
                                    child: const Text(
                                      'Register now',
                                      style: TextStyle(
                                          color: Colors.blue, // Make the text blue so it looks clickable
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ]),
                          ),
                          const SizedBox(height: 40)
                        ],
                      ),
                    ),
                  ]),
            ),
          )),
    );
  }
}

// This creates the auth page that determines if the user can
// proceed to the program or go back to the login/register pages
class Auth extends StatelessWidget {
  const Auth({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<User?>(
            // If a returning user, redirected to the mainpage, and if existing user, goes to the help page
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (reg) {
                  return const HelpScreen();
                } else {
                  return const MainPage();
                }
              } else {
                return const LoginOrRegisterPage();
              }
            }));
  }
}

// Creates stateful widgets for the login and register pages
class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});
  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

// Toggles between the login and register page
class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  // initially show login page
  bool showLoginPage = true;

  // toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Adds login and register pages
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
}
// Creates a stateful widget for the register page
class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text Editing Controllers for the username and password
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // This method is used to sign user up is used to create a new account in firebase
  void signUserUp() async {
    // Only proceeds if the password and confirm password contain the same thing
    if (passwordController.text == confirmPasswordController.text) {
      // Sets all the user variables to 0 or empty
      userSemesters = 0;
      grades = [];
      ap = 0;
      honors = 0;
      weightedGPA = 0;
      unweightedGPA = 0;
      gpaScale = [];
      classType = [];
      reg = true;

      // Sets the email as what they entered
      email = usernameController.text;
      // Creates an account using the email and password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: usernameController.text, password: passwordController.text);
      // Creates the information sent to firebase, and assigns it to different variables
      final send = {
        'Number of Semesters': userSemesters,
        'Unweighted GPA': unweightedGPA,
        'Weighted GPA': weightedGPA,
        'Grades': grades,
        'Semester Types': classType,
        'Honors Semesters': honors,
        'AP Semesters': ap
      };
      // Sends the data to database
      db.collection("users").doc(email).set(send);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Creates a container for the background of the register page
        color: const Color(0xff0c142c),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              // Defines the children, including the column and scrollability
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: 250,
                      // Adds the logo as the asset image on the register page
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('assets/images/Logo.png')))
                    ),
                    Container(
                      // Creating and curving the bottom box of the register page
                      decoration: const BoxDecoration(
                          color: Color(0xfff1f4f8),
                          // Defining border radius to achieve curved, smooth look
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(60),
                              topRight: Radius.circular(60))),
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      // logo
                      const Icon(
                        Icons.lock,
                        size: 100,
                      ),
                      // Let's create an account for you
                      const Text(
                          "                Let's create an account for you! \n Make sure your password is at least 6 characters!",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 25),
                      // username textfield
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: TextField(
                          // used to control the text
                          controller: usernameController,
                          obscureText: false,
                          decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              // Defines fill color for email field, as well as the hinttext
                              fillColor: Colors.grey.shade200,
                              filled: true,
                              hintText: "Email",
                              hintStyle: TextStyle(color: Colors.grey[500])),
                        ),
                      ),

                      const SizedBox(height: 10),
                      // password textfield
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: TextField(
                          // used to change the text
                          controller: passwordController,
                          // used to hide the texts using dots
                          obscureText: true,
                          decoration: InputDecoration(
                            // Enables the outline of the input area
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              fillColor: Colors.grey.shade200,
                              filled: true,
                              // Text before user starts typing
                              hintText: "Password",
                              hintStyle: TextStyle(color: Colors.grey[500])),
                        ),
                      ),

                      const SizedBox(height: 10),
                      // confirm password textfield
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: TextField(
                          // Uses controller to edit text
                          controller: confirmPasswordController,
                          // Makes the text hidden using dots
                          obscureText: true,
                          decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              fillColor: Colors.grey.shade200,
                              filled: true,
                              // Placeholder text - before the user starts typing
                              hintText: "Confirm Password",
                              hintStyle: TextStyle(color: Colors.grey[500])),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // creates the sign up button
                      // Checks for taps on the box
                      GestureDetector(
                        onTap: signUserUp,
                        child: Container(
                          // Adds padding so that the container is more readable
                            padding: const EdgeInsets.all(25),
                            margin: const EdgeInsets.symmetric(horizontal: 25),
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Center(
                              // Creates the sign up button
                              child: Text(
                                "Sign Up",
                                // Defines the style of the Sign Up Button
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            )),
                      ),

                      // not a member? register now
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?',
                                  style: TextStyle(color: Colors.black)),
                              const SizedBox(width: 4),
                              // Checks for tap on the text to switch pages
                              GestureDetector(
                                onTap: widget.onTap,
                                child: const Text(
                                  // Text to redirect to existing account

                                  'Login now',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ]),
                      )
                    ])
                    ),
                  ]
                ),
              ),
            )));
  }
}

// Defining home page class
class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

// Creates a stateful widget, and defines the widget's state in '_HomePageState'
class _AIPageState extends State<AIPage> {
  late genai.GenerativeModel model;

  // Defines a list called messages, which is to be used when displaying chats back and forth between chatbot and user
  List<ChatMessage> messages = [];

  // Defining users in chat interaction as gemini and current user, with corresponding names
  ChatUser currentUser = ChatUser(id: "0", firstName: "Me");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "GradeGemini");

  // Initializes Gemini
  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  // Defines basic information about the output of the app - how creative its supposed to be and how many tokens it uses
  void _initializeModel() {
    final generationConfig = genai.GenerationConfig(
      temperature: 0.9,
      topP: 0.95,
      topK: 64,
      maxOutputTokens: 8192,
    );

    // Defining basic variables necessary to run the model, such as the gemini version that is being used and api key

    model = genai.GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiApiKey,
      // Configures the generation of text based on parameters defined above.
      generationConfig: generationConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Defines the appbar, centers the title of the page, and 
      appBar: AppBar(
        centerTitle: true,
        // Setting the color of the back button
        iconTheme: const IconThemeData(
    color: Colors.white, //change your color here
  ),
        // Creating the 'skeleton' of the AI page, setting the title and background color
        title: const Text("GradeGemini", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff0A1930),
      ),
      body: _buildUI(),
    );
  }

  // Returns a widget that is used to build a part of the UI
  Widget _buildUI() {
    return Container(
      color: const Color(0xff0A1930),
      child: DashChat(
        // Defines the current user, which contains the name of the user
        currentUser: currentUser,
        // Triggers when a new message is sent, handles the logic of sending messages
        onSend: _sendMessage,
        messages: messages,
      ),
    );
  }

  // Displays the messages in the chat area
  void _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      // Defining final variables to create and print gemini's response

      final prompt = _buildPrompt(chatMessage.text);
      final content = [genai.Content.text(prompt)];
      final response = await model.generateContent(content);

      // If a new conversation with gemini is started, the date and time is recorded
      // The text of the reponse is set to the generated response
      if (response.text != null) {
        final geminiMessage = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: response.text!,
        );

        // Displays the messages in the chat area
        setState(() {
          messages = [geminiMessage, ...messages];
        });
      }
      // Catches any errors that occured while generating gemini's response
    } catch (e) {
      // prints the error, so that the user is aware of what went wrong
      debugPrint('Error generating response: $e');
    }
  }

  // Provides model with data necessary to complete specified tasks, e.g. data about grading scale used, navigation in app, and more
  String _buildPrompt(String userInput) {
    return '''
You are GradeGemini. When a user asks you who you are, you are to respond in a friendly tone, and state your name, You are to help users about their grades, particularly with telling them how to use GradePoint to calculate their weighted and unweighted gpas by entering their classes not with anything they need, and you aren't a large language model, you're a personal assistant. Don't state that you are to help users on this data set, or that you are friendly. Don't introduce yourself in each response. Avoid using emojis and any modifications to your text responses. To navigate between pages, you have to click on the corresponding icon at the bottom of the nav bar. For the classes page, it's a check mark, for the report page, its a menu, and for the help page, it's a question mark.  When asked about the grading scale, respond with information about the grading scale. The grading scale used is the Northshore School District Grading Scale, and goes as follows, include both the corresponding percentage value as well as the grade point value. To calculate the weighted GPA, 1 grade point is added if the class is an AP class, and 0.5 grade points are added if the class is an honors class. The app is called GradePoint, but the value that is added when users have honors and ap classes is also called a grade point, when a user asks a question like "what is grade point" you should respond by telling them about the app. To login to the app, the user must use the email and password that they created their account with. If they don't have an account, they can create one by navigating to the register page, and creating one there. To logout of the app, the user can click on the logout icon that's located at the top of every page. The purpose of GradePoint is to create a seamless solution that helps students calculate both their weighted and unweighted gpas with ease. If asked about anything besides the aforementioned topics, say "Unfortunately, I am not trained to answer that yet. Is there anything else that I can help you with?". if theyre asking about a page that isn't listed, tell them that the page doesn't exist.

User input: $userInput
GradeGemini's response:
''';
  }
}