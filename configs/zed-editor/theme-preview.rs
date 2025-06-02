/// Hi
/// <https://example.com>
#[derive(foo::Deserialize)]
pub enum FooBar {
	#[serde(default)]
	Ax,
	B(&'static u32),
	C {
		x: bool
	}
}
#[cfg(feature = "hi")]
macro_rules! ab {
    ($foo: ident) => {

    };
}
impl FooBar {
	pub fn new<T: ?Sized + Send>() -> Self {
		todo!()
	}
}
impl X for dyn FooBar {

}
impl Module for FooBar {
	type Config<'a> = Config;

	const NAME: &'static str = "constant\ngoes\there";

    fn initialize<'conf>(config: Self::Config<'conf>) -> Result<Self, Error> {
		Ok(Self { config })
	}

    fn run(&mut self, foo: String) -> Result<Run, Error> {
    	Foo::bar(baz([1, 2 + 14 * 15, 3]));
    	foo.bar();
    	return thing::format!("{abc}{}", d, NAME, true)
    }
}
