## RPFloatingPlaceholders

UITextField and UITextView subclasses with placeholders that change into floating labels when the fields are populated with text.  

Please see the included example app for sample usage.

### Options:

**Animate upward (default)**

![Upwards animation](http://i.imgur.com/HLehhbQ.gif)

**Animate downward**

![Downwards animation](http://i.imgur.com/DrAECwk.gif)

### Supports: 
ARC & iOS 7+

**Caveat:** I am using `setFrame:` so these classes probably won't play well with storyboards using Auto Layout at runtime.  You should still be able to programmatically add them to a view that has Auto Layout enabled and they should work fine, but loading from a storyboard doesn't set the frames correctly.  I welcome any pull requests to fix this since I don't have much experience with Auto Layout.

### A little help from my friends:
Please feel free to fork and create a pull request for bug fixes or improvements.

### Credit:
[Credit for the design concept goes to Matt D. Smith](http://dribbble.com/shots/1254439--GIF-Mobile-Form-Interaction).