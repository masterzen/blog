--- 

title: How do you like your Mocks served?
date: 2009-01-16 22:28:14 +01:00
comments: true
wordpress_id: 9
wordpress_url: http://www.masterzen.fr/?p=9
categories: 
- Programming
- Java
- Testing
tags: 
- testing
- Java
- mock
- unit testing
---
I like them refreshing, of course:

![](http://mockito.googlecode.com/svn/wiki/images/logo.jpg)

[Mockito ](http://code.google.com/p/mockito/) is the new Java [mock library](http://en.wikipedia.org/wiki/Mock_Object) on the block, with lots of interesting features. It replaced JMock in almost all my Java projects, mainly because:- the syntax produces_ clear and readable test code_ (see below for an example), 
because it doesn't abuse of anonymous class and methods are really methods.

- stub and verification happens _logically_, and at different place
- _no replay_ or framework control methods ala EasyMock
- fully integrated to Junit (using @RunWith for instance)
- helpful _annotations to create mock_ automagically
- it promotes _simple tests by nature_ (and that's essential to my eyes)

Basically, you can only do two things with _Mockito_:

- stub, or
- verify :-)

Enough discussion, let's focus on an example:

``` java
@Test
public void itShouldComputeAndSetThePlayerRank() 
{  
  // creating a mock from an interface  
  // is as easy as that:  
  Player p = mock(Player.class)  
  
  // stub a method  
  when(p.getScore()).thenReturn(5);  
  
  // our imaginary SUT  
  ELOCalculator.computeRank(p);  
  
  // let's verify our rank has been computed  
  verify(p).setRank(12);
}
```

Due to its use of Generics and Java 5 autoboxing, the syntax is very clean, clear and readable.
But that's not all, _Mockito_ provide a _Junit 4_ runner that simplifies mock creation with the help of 
annotations:

``` java
@RunWith(MockitoJUnit44Runner.class)
public class OurImaginaryTestCase
{  
  @Mock
  private Player player;  
  
  @Test  
  public void playerShouldBeRanked()  
  {     
    // we can use player directly here,     
    // it is mocked to the Player Interface  
  }
}
```

Of course during the verification phase of the test you can check for

- the number of calls (or check for no calls at all)
- the arguments (Mockito defines lots of useful arguments matcher, and you can plug any Hamcrest matchers),
- the call order,
- and for stubbing, you can also throw exception, return values, or define callbacks that will be called when a return value is needed.

In a word it's really powerful. It is also possible to [spy on concrete objects](http://xunitpatterns.com/Test%20Spy.html) 
however as the manual says [this is not partial mocking](http://groups.google.com/group/mockito/browse_thread/thread/3945fe1eca2954e7/007b58d8c2a42cb8?lnk=gst&q=partial+mocking#007b58d8c2a42cb8):

so you can't use this method to check that the method under test calls other
methods of the same object.Here's an example of what I mean (the following
test passes):

``` java
public class RealObject 
{
  public int a() 
  { 
    return 10; 
  } 
  
  public int b() 
  { 
    return 20 + a(); 
  }
}

@Test
public final void test1()
{ 
  RealObject real = new RealObject(); 
  RealObject spy = spy(real);
  when(spy.a()).thenReturn(12); 
  
  // notice the 30 here 
  assertThat(spy.b(), equalTo(30));
}
```

See [Mockito author's last blog post](http://monkeyisland.pl/2009/01/13/subclass-and-override-vs-partial-mocking-vs-refactoring/)
about the subject or this [mockito mailing list post](http://groups.google.com/group/mockito/browse_thread/thread/d856d10824027f58#).

Basically the code should be refactored or we could use a subclass to overcome
this.

There is also a debate about stubbing and verifying (the same call).
Usually you don't want to do that. Stubbing should be enough, if your code
succeed then the call was implicitly verified. 
So usually if you stub there is no need to verify, and if you verify you don't 
need to stub (except if you need to return something critical to the rest of the code,
in which case you don't need verification).
 Once again, [Mockito's author has a great post on the_stubbing or verifying debate_](http://monkeyisland.pl/2008/04/26/asking-and-telling/).

Of course if you are an _Eclipse_ user, do not forget to add to the list of Favorites all
Mockito static import, so that Content Assist knows all the matchers.

Happy unit testing with Mockito :-)
