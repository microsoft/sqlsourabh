using System;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Diagnostics.Contracts;
using System.Runtime.InteropServices;
using System.Runtime.Loader;
using Microsoft.Extensions.Logging;


namespace IronOreSilicaPercent
{
    public class AtomicBoolean
    {
        int underlying;

        public AtomicBoolean(bool value)
        {
            this.underlying = value ? 1 : 0;
        }

        public AtomicBoolean()
            : this(false)
        {
        }

        public static implicit operator bool(AtomicBoolean value) => value.Get();

        public bool Get() => Interlocked.Exchange(ref this.underlying, this.underlying) != 0;

        public void Set(bool value) => Interlocked.Exchange(ref this.underlying, value ? 1 : 0);

        public bool GetAndSet(bool value) => Interlocked.Exchange(ref this.underlying, value ? 1 : 0) != 0;

        public bool CompareAndSet(bool expected, bool result)
        {
            int e = expected ? 1 : 0;
            int r = result ? 1 : 0;
            return Interlocked.CompareExchange(ref this.underlying, r, e) == e;
        }
    }
    public interface ITransientErrorDetectionStrategy
    {
        /// <summary>
        /// Determines whether the specified exception represents a transient failure that can be compensated by a retry.
        /// </summary>
        /// <param name="ex">The exception object to be verified.</param>
        /// <returns>true if the specified exception is considered as transient; otherwise, false.</returns>
        bool IsTransient(Exception ex);
    }

    public delegate bool ShouldRetry(int retryCount, Exception lastException, out TimeSpan delay);

    static class Guard
    {
        /// <summary>
        /// Checks a string argument to ensure that it isn't null or empty.
        /// </summary>
        /// <param name="argumentValue">The argument value to check.</param>
        /// <param name="argumentName">The name of the argument.</param>
        /// <returns>The return value should be ignored. It is intended to be used only when validating arguments during instance creation (for example, when calling the base constructor).</returns>
        public static bool ArgumentNotNullOrEmptyString(string argumentValue, string argumentName)
        {
            ArgumentNotNull(argumentValue, argumentName);
            if (argumentValue.Length == 0)
            {
                throw new ArgumentException(
                    string.Format(
                        CultureInfo.CurrentCulture,
                        "String {0} cannot be empty",
                        new object[]
                        {
                            argumentName
                        }));
            }

            return true;
        }

        /// <summary>
        /// Checks an argument to ensure that it isn't null.
        /// </summary>
        /// <param name="argumentValue">The argument value to check.</param>
        /// <param name="argumentName">The name of the argument.</param>
        /// <returns>The return value should be ignored. It is intended to be used only when validating arguments during instance creation (for example, when calling the base constructor).</returns>
        public static bool ArgumentNotNull(object argumentValue, string argumentName)
        {
            if (argumentValue == null)
            {
                throw new ArgumentNullException(argumentName);
            }

            return true;
        }

        /// <summary>
        /// Checks an argument to ensure that its 32-bit signed value isn't negative.
        /// </summary>
        /// <param name="argumentValue">The <see cref="T:System.Int32" /> value of the argument.</param>
        /// <param name="argumentName">The name of the argument for diagnostic purposes.</param>
        public static void ArgumentNotNegativeValue(int argumentValue, string argumentName)
        {
            if (argumentValue < 0)
            {
                throw new ArgumentOutOfRangeException(
                    argumentName,
                    argumentValue,
                    string.Format(
                        CultureInfo.CurrentCulture,
                        "Argument {0} cannot be negative",
                        new object[]
                        {
                            argumentName
                        }));
            }
        }

        /// <summary>
        /// Checks an argument to ensure that its 64-bit signed value isn't negative.
        /// </summary>
        /// <param name="argumentValue">The <see cref="T:System.Int64" /> value of the argument.</param>
        /// <param name="argumentName">The name of the argument for diagnostic purposes.</param>
        public static void ArgumentNotNegativeValue(long argumentValue, string argumentName)
        {
            if (argumentValue < 0L)
            {
                throw new ArgumentOutOfRangeException(
                    argumentName,
                    argumentValue,
                    string.Format(
                        CultureInfo.CurrentCulture,
                        "Argument {0} cannot be negative",
                        new object[]
                        {
                            argumentName
                        }));
            }
        }

        /// <summary>
        /// Checks an argument to ensure that its value doesn't exceed the specified ceiling baseline.
        /// </summary>
        /// <param name="argumentValue">The <see cref="T:System.Double" /> value of the argument.</param>
        /// <param name="ceilingValue">The <see cref="T:System.Double" /> ceiling value of the argument.</param>
        /// <param name="argumentName">The name of the argument for diagnostic purposes.</param>
        public static void ArgumentNotGreaterThan(double argumentValue, double ceilingValue, string argumentName)
        {
            if (argumentValue > ceilingValue)
            {
                throw new ArgumentOutOfRangeException(
                    argumentName,
                    argumentValue,
                    string.Format(
                        CultureInfo.CurrentCulture,
                        "Argument {0} cannot be greater than baseline value {1}",
                        new object[]
                        {
                            argumentName,
                            ceilingValue
                        }));
            }
        }
    }
    public class FixedInterval : RetryStrategy
    {
        readonly int retryCount;

        readonly TimeSpan retryInterval;

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.FixedInterval" /> class.
        /// </summary>
        public FixedInterval()
            : this(DefaultClientRetryCount)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.FixedInterval" /> class with the specified number of retry attempts.
        /// </summary>
        /// <param name="retryCount">The number of retry attempts.</param>
        public FixedInterval(int retryCount)
            : this(retryCount, DefaultRetryInterval)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.FixedInterval" /> class with the specified number of retry attempts, time interval, and retry strategy.
        /// </summary>
        /// <param name="retryCount">The number of retry attempts.</param>
        /// <param name="retryInterval">The time interval between retries.</param>
        public FixedInterval(int retryCount, TimeSpan retryInterval)
            : this(retryCount, retryInterval, DefaultFirstFastRetry)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.FixedInterval" /> class with the specified number of retry attempts, time interval, retry strategy, and fast start option.
        /// </summary>
        /// <param name="retryCount">The number of retry attempts.</param>
        /// <param name="retryInterval">The time interval between retries.</param>
        /// <param name="firstFastRetry">true to immediately retry in the first attempt; otherwise, false. The subsequent retries will remain subject to the configured retry interval.</param>
        public FixedInterval(int retryCount, TimeSpan retryInterval, bool firstFastRetry)
            : base(firstFastRetry)
        {
            Guard.ArgumentNotNegativeValue(retryCount, "retryCount");
            Guard.ArgumentNotNegativeValue(retryInterval.Ticks, "retryInterval");
            this.retryCount = retryCount;
            this.retryInterval = retryInterval;
        }

        /// <summary>
        /// Returns the corresponding ShouldRetry delegate.
        /// </summary>
        /// <returns>The ShouldRetry delegate.</returns>
        public override ShouldRetry GetShouldRetry()
        {
            if (this.retryCount == 0)
            {
                return (int currentRetryCount, Exception lastException, out TimeSpan interval) =>
                {
                    interval = TimeSpan.Zero;
                    return false;
                };
            }

            return (int currentRetryCount, Exception lastException, out TimeSpan interval) =>
            {
                if (currentRetryCount < this.retryCount)
                {
                    interval = this.retryInterval;
                    return true;
                }

                interval = TimeSpan.Zero;
                return false;
            };
        }
    }
    public class Incremental : RetryStrategy
    {
        readonly int retryCount;
        readonly TimeSpan initialInterval;
        readonly TimeSpan increment;

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.Incremental" /> class.
        /// </summary>
        public Incremental()
            : this(DefaultClientRetryCount, DefaultRetryInterval, DefaultRetryIncrement)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.Incremental" /> class with the specified name and retry settings.
        /// </summary>
        /// <param name="retryCount">The number of retry attempts.</param>
        /// <param name="initialInterval">The initial interval that will apply for the first retry.</param>
        /// <param name="increment">The incremental time value that will be used to calculate the progressive delay between retries.</param>
        public Incremental(int retryCount, TimeSpan initialInterval, TimeSpan increment)
            : this(retryCount, initialInterval, increment, DefaultFirstFastRetry)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.Incremental" /> class with the specified number of retry attempts, time interval, retry strategy, and fast start option.
        /// </summary>
        /// <param name="retryCount">The number of retry attempts.</param>
        /// <param name="initialInterval">The initial interval that will apply for the first retry.</param>
        /// <param name="increment">The incremental time value that will be used to calculate the progressive delay between retries.</param>
        /// <param name="firstFastRetry">true to immediately retry in the first attempt; otherwise, false. The subsequent retries will remain subject to the configured retry interval.</param>
        public Incremental(int retryCount, TimeSpan initialInterval, TimeSpan increment, bool firstFastRetry)
            : base(firstFastRetry)
        {
            Guard.ArgumentNotNegativeValue(retryCount, "retryCount");
            Guard.ArgumentNotNegativeValue(initialInterval.Ticks, "initialInterval");
            Guard.ArgumentNotNegativeValue(increment.Ticks, "increment");
            this.retryCount = retryCount;
            this.initialInterval = initialInterval;
            this.increment = increment;
        }

        /// <summary>
        /// Returns the corresponding ShouldRetry delegate.
        /// </summary>
        /// <returns>The ShouldRetry delegate.</returns>
        public override ShouldRetry GetShouldRetry()
        {
            return (int currentRetryCount, Exception lastException, out TimeSpan retryInterval) =>
            {
                if (currentRetryCount < this.retryCount)
                {
                    retryInterval = TimeSpan.FromMilliseconds(this.initialInterval.TotalMilliseconds + this.increment.TotalMilliseconds * currentRetryCount);
                    return true;
                }

                retryInterval = TimeSpan.Zero;
                return false;
            };
        }
    }
    public class DelegateErrorDetectionStrategy : ITransientErrorDetectionStrategy
    {
        readonly Func<Exception, bool> underlying;

        public DelegateErrorDetectionStrategy(Func<Exception, bool> isTransient)
        {
            this.underlying = Preconditions.CheckNotNull(isTransient);
        }

        public bool IsTransient(Exception ex) => this.underlying(ex);
    }
    public abstract class RetryStrategy
    {
        public static readonly int DefaultClientRetryCount = 10;
        public static readonly TimeSpan DefaultClientBackoff = TimeSpan.FromSeconds(10.0);
        public static readonly TimeSpan DefaultMaxBackoff = TimeSpan.FromSeconds(30.0);
        public static readonly TimeSpan DefaultMinBackoff = TimeSpan.FromSeconds(1.0);
        public static readonly TimeSpan DefaultRetryInterval = TimeSpan.FromSeconds(1.0);
        public static readonly TimeSpan DefaultRetryIncrement = TimeSpan.FromSeconds(1.0);
        public static readonly bool DefaultFirstFastRetry = true;

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy" /> class.
        /// </summary>
        /// <param name="firstFastRetry">true to immediately retry in the first attempt; otherwise, false. The subsequent retries will remain subject to the configured retry interval.</param>
        protected RetryStrategy(bool firstFastRetry)
        {
            this.FastFirstRetry = firstFastRetry;
        }

        /// <summary>
        /// Returns a default policy that performs no retries, but invokes the action only once.
        /// </summary>
        public static RetryStrategy NoRetry { get; } = new FixedInterval(0, DefaultRetryInterval);

        /// <summary>
        /// Returns a default policy that implements a fixed retry interval configured with the <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultClientRetryCount" /> and <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultRetryInterval" /> parameters.
        /// The default retry policy treats all caught exceptions as transient errors.
        /// </summary>
        public static RetryStrategy DefaultFixed { get; } = new FixedInterval(DefaultClientRetryCount, DefaultRetryInterval);

        /// <summary>
        /// Returns a default policy that implements a progressive retry interval configured with the <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultClientRetryCount" />, <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultRetryInterval" />, and <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultRetryIncrement" /> parameters.
        /// The default retry policy treats all caught exceptions as transient errors.
        /// </summary>
        public static RetryStrategy DefaultProgressive { get; } = new Incremental(DefaultClientRetryCount, DefaultRetryInterval, DefaultRetryIncrement);

        /// <summary>
        /// Returns a default policy that implements a random exponential retry interval configured with the <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultClientRetryCount" />, <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultMinBackoff" />, <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultMaxBackoff" />, and <see cref="F:Microsoft.Azure.Devices.Edge.Util.TransientFaultHandling.RetryStrategy.DefaultClientBackoff" /> parameters.
        /// The default retry policy treats all caught exceptions as transient errors.
        /// </summary>
        public static RetryStrategy DefaultExponential { get; } = new ExponentialBackoff(DefaultClientRetryCount, DefaultMinBackoff, DefaultMaxBackoff, DefaultClientBackoff);

        /// <summary>
        /// Gets or sets a value indicating whether the first retry attempt will be made immediately,
        /// whereas subsequent retries will remain subject to the retry interval.
        /// </summary>
        public bool FastFirstRetry { get; set; }

        /// <summary>
        /// Returns the corresponding ShouldRetry delegate.
        /// </summary>
        /// <returns>The ShouldRetry delegate.</returns>
        public abstract ShouldRetry GetShouldRetry();
    }
    public struct Option<T> : IEquatable<Option<T>>
    {
        internal Option(T value, bool hasValue)
        {
            this.Value = value;
            this.HasValue = hasValue;
        }

        public bool HasValue { get; }

        T Value { get; }

        [Pure]
        public static bool operator ==(Option<T> opt1, Option<T> opt2) => opt1.Equals(opt2);

        [Pure]
        public static bool operator !=(Option<T> opt1, Option<T> opt2) => !opt1.Equals(opt2);

        [Pure]
        public bool Equals(Option<T> other)
        {
            if (!this.HasValue && !other.HasValue)
            {
                return true;
            }
            else if (this.HasValue && other.HasValue)
            {
                return EqualityComparer<T>.Default.Equals(this.Value, other.Value);
            }

            return false;
        }

        [Pure]
        public override bool Equals(object obj) => obj is Option<T> && this.Equals((Option<T>)obj);

        [Pure]
        public override int GetHashCode()
        {
            if (this.HasValue)
            {
                return this.Value == null ? 1 : this.Value.GetHashCode();
            }

            return 0;
        }

        [Pure]
        public override string ToString() =>
            this.Map(v => v != null ? string.Format(CultureInfo.InvariantCulture, "Some({0})", v) : "Some(null)").GetOrElse("None");

        [Pure]
        public IEnumerable<T> ToEnumerable()
        {
            if (this.HasValue)
            {
                yield return this.Value;
            }
        }

        [Pure]
        public IEnumerator<T> GetEnumerator()
        {
            if (this.HasValue)
            {
                yield return this.Value;
            }
        }

        [Pure]
        public bool Contains(T value)
        {
            if (this.HasValue)
            {
                return this.Value == null ? value == null : this.Value.Equals(value);
            }

            return false;
        }

        /// <summary>
        /// Evaluates to true if and only if the option has a value and <paramref name="predicate"/>
        /// returns <c>true</c>.
        /// </summary>
        [Pure]
        public bool Exists(Func<T, bool> predicate) => this.HasValue && predicate(this.Value);

        /// <summary>
        /// If this option has a value then returns that. If there is no value then returns
        /// <paramref name="alternative"/>.
        /// </summary>
        /// <param name="alternative"></param>
        /// <returns></returns>
        public T GetOrElse(T alternative) => this.HasValue ? this.Value : alternative;

        public T GetOrElse(Func<T> alternativeMaker) => this.HasValue ? this.Value : alternativeMaker();

        public Option<T> Else(Option<T> alternativeOption) => this.HasValue ? this : alternativeOption;

        public Option<T> Else(Func<Option<T>> alternativeMaker) => this.HasValue ? this : alternativeMaker();

        [Pure]
        public T OrDefault() => this.HasValue ? this.Value : default(T);

        public T Expect<TException>(Func<TException> exception)
            where TException : Exception
        {
            return this.HasValue
                ? this.Value
                : throw exception();
        }

        /// <summary>
        /// If the option has a value then it invokes <paramref name="some"/>. If there is no value
        /// then it invokes <paramref name="none"/>.
        /// </summary>
        /// <returns>The value returned by either <paramref name="some"/> or <paramref name="none"/>.</returns>
        [Pure]
        public TResult Match<TResult>(Func<T, TResult> some, Func<TResult> none) => this.HasValue ? some(this.Value) : none();

        /// <summary>
        /// Conditionally invokes <paramref name="action"/> with the value of this option
        /// object if this option has a value. This method is a no-op if there is no value
        /// stored in this option.
        /// </summary>
        public void ForEach(Action<T> action)
        {
            if (this.HasValue)
            {
                action(this.Value);
            }
        }

        public Task ForEachAsync(Func<T, Task> action) => this.HasValue ? action(this.Value) : Task.CompletedTask;

        /// <summary>
        /// If this option has a value then it transforms it into a new option instance by
        /// calling the <paramref name="mapping"/> callback.  It will follow exception if callback returns null.
        /// Returns <see cref="Option.None{T}"/> if there is no value.
        /// </summary>
        [Pure]
        public Option<TResult> Map<TResult>(Func<T, TResult> mapping)
        {
            return this.Match(
                some: value => Option.Some(mapping(value)),
                none: Option.None<TResult>);
        }

        [Pure]
        public Option<TResult> FlatMap<TResult>(Func<T, Option<TResult>> mapping) => this.Match(
            some: mapping,
            none: Option.None<TResult>);

        [Pure]
        public Option<T> Filter(Func<T, bool> predicate)
        {
            Option<T> original = this;
            return this.Match(
                some: value => predicate(value) ? original : Option.None<T>(),
                none: () => original);
        }
    }
    public static class Option
    {
        /// <summary>
        /// Creates an <c>Option &lt;T&gt;</c> with <paramref name="value"/> and marks
        /// the option object as having a value, i.e., <c>Option&lt;T&gt;.HasValue == true</c>.
        /// </summary>
        public static Option<T> Some<T>(T value)
        {
            Preconditions.CheckNotNull(value, nameof(value));

            return new Option<T>(value, true);
        }

        /// <summary>
        /// Creates an <c>Option &lt;T&gt;</c> with a default value (<c>default(T)</c>) and marks
        /// the option object as having no value, i.e., <c>Option&lt;T&gt;.HasValue == false</c>.
        /// </summary>
        public static Option<T> None<T>() => new Option<T>(default(T), false);

        public static Option<T> Maybe<T>(T value)
            where T : class => value == null ? None<T>() : Some(value);

        public static Option<T> Maybe<T>(T? value)
            where T : struct, IComparable => value.HasValue ? Some(value.Value) : None<T>();
    }
    public class Preconditions
    {
        /// <summary>
        /// Checks that a reference isn't null. Throws ArgumentNullException if null.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="reference"></param>
        /// <returns>The reference</returns>
        public static T CheckNotNull<T>(T reference) => CheckNotNull(reference, string.Empty, string.Empty);

        /// <summary>
        /// Checks that a reference isn't null. Throws ArgumentNullException if null.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="reference"></param>
        /// <param name="paramName"></param>
        /// <returns>The reference</returns>
        public static T CheckNotNull<T>(T reference, string paramName) => CheckNotNull(reference, paramName, string.Empty);

        /// <summary>
        /// Checks that a reference isn't null. Throws ArgumentNullException if null.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="reference"></param>
        /// <param name="paramName"></param>
        /// <param name="message"></param>
        /// <returns>The reference</returns>
        public static T CheckNotNull<T>(T reference, string paramName, string message)
        {
            if (reference == null)
            {
                if (string.IsNullOrEmpty(paramName))
                {
                    throw new ArgumentNullException();
                }
                else
                {
                    throw string.IsNullOrEmpty(message) ? new ArgumentNullException(paramName) : new ArgumentNullException(paramName, message);
                }
            }

            return reference;
        }

        /// <summary>
        /// Throws ArgumentException if the bool expression is false.
        /// </summary>
        /// <param name="expression"></param>
        public static void CheckArgument(bool expression)
        {
            if (!expression)
            {
                throw new ArgumentException();
            }
        }

        /// <summary>
        /// Throws ArgumentException if the bool expression is false.
        /// </summary>
        /// <param name="expression"></param>
        /// <param name="message"></param>
        public static void CheckArgument(bool expression, string message)
        {
            if (!expression)
            {
                throw new ArgumentException(message);
            }
        }

        /// <summary>
        ///  Checks that an Enum is defined. Throws ArgumentOutOfRangeException is not.
        /// </summary>
        /// <typeparam name="T">Enum Type.</typeparam>
        /// <param name="status">Value.</param>
        /// <returns></returns>
        public static T CheckIsDefined<T>(T status)
        {
            Type enumType = typeof(T);
            if (!Enum.IsDefined(enumType, status))
            {
                throw new ArgumentOutOfRangeException(status + " is not a valid value for " + enumType.FullName + ".");
            }

            return status;
        }

        /// <summary>
        /// This checks that the item is greater than or equal to the low value.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="item">Item to check.</param>
        /// <param name="low">Inclusive low value.</param>
        /// <returns></returns>
        public static T CheckRange<T>(T item, T low)
            where T : IComparable<T> =>
            CheckRange(item, low, nameof(item));

        /// <summary>
        /// This checks that the item is greater than or equal to the low value.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="item">Item to check.</param>
        /// <param name="low">Inclusive low value.</param>
        /// <param name="paramName"></param>
        /// <returns></returns>
        public static T CheckRange<T>(T item, T low, string paramName)
            where T : IComparable<T> =>
            CheckRange(item, low, paramName, string.Empty);

        /// <summary>
        /// This checks that the item is greater than or equal to the low value.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="item">Item to check.</param>
        /// <param name="low">Inclusive low value.</param>
        /// <param name="paramName"></param>
        /// <param name="message"></param>
        /// <returns></returns>
        public static T CheckRange<T>(T item, T low, string paramName, string message)
            where T : IComparable<T>
        {
            if (item.CompareTo(low) < 0)
            {
                throw new ArgumentOutOfRangeException(paramName, item, message);
            }

            return item;
        }

        /// <summary>
        /// This checks that the item is in the range [low, high).
        /// Throws ArgumentOutOfRangeException if out of range.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="item">Item to check.</param>
        /// <param name="low">Inclusive low value.</param>
        /// <param name="high">Exclusive high value</param>
        /// <returns></returns>
        public static T CheckRange<T>(T item, T low, T high)
            where T : IComparable<T> =>
            CheckRange(item, low, high, nameof(item));

        /// <summary>
        /// This checks that the item is in the range [low, high).
        /// Throws ArgumentOutOfRangeException if out of range.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="item">Item to check.</param>
        /// <param name="low">Inclusive low value.</param>
        /// <param name="high">Exclusive high value</param>
        /// <param name="paramName"></param>
        /// <returns></returns>
        public static T CheckRange<T>(T item, T low, T high, string paramName)
            where T : IComparable<T> =>
            CheckRange(item, low, high, paramName, string.Empty);

        /// <summary>
        /// This checks that the item is in the range [low, high).
        /// Throws ArgumentOutOfRangeException if out of range.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="item">Item to check.</param>
        /// <param name="low">Inclusive low value.</param>
        /// <param name="high">Exclusive high value</param>
        /// <param name="paramName"></param>
        /// <param name="message"></param>
        /// <returns></returns>
        public static T CheckRange<T>(T item, T low, T high, string paramName, string message)
            where T : IComparable<T>
        {
            if (item.CompareTo(low) < 0 || item.CompareTo(high) >= 0)
            {
                throw new ArgumentOutOfRangeException(paramName, item, message);
            }

            return item;
        }

        /// <summary>
        /// Checks if the string is null or whitespace, and throws ArgumentException if it is.
        /// </summary>
        /// <param name="value"></param>
        /// <param name="paramName"></param>
        public static string CheckNonWhiteSpace(string value, string paramName)
        {
            CheckArgument(!string.IsNullOrWhiteSpace(value), $"{paramName} is null or whitespace.");
            return value;
        }
    }
    public class ExponentialBackoff : RetryStrategy
    {
        readonly int retryCount;
        readonly TimeSpan minBackoff;
        readonly TimeSpan maxBackoff;
        readonly TimeSpan deltaBackoff;

        public ExponentialBackoff()
            : this(DefaultClientRetryCount, DefaultMinBackoff, DefaultMaxBackoff, DefaultClientBackoff)
        {
        }

        public ExponentialBackoff(int retryCount, TimeSpan minBackoff, TimeSpan maxBackoff, TimeSpan deltaBackoff)
            : this(retryCount, minBackoff, maxBackoff, deltaBackoff, DefaultFirstFastRetry)
        {
        }

        public ExponentialBackoff(int retryCount, TimeSpan minBackoff, TimeSpan maxBackoff, TimeSpan deltaBackoff, bool firstFastRetry)
            : base(firstFastRetry)
        {
            Guard.ArgumentNotNegativeValue(retryCount, "retryCount");
            Guard.ArgumentNotNegativeValue(minBackoff.Ticks, "minBackoff");
            Guard.ArgumentNotNegativeValue(maxBackoff.Ticks, "minBackoff");
            Guard.ArgumentNotNegativeValue(deltaBackoff.Ticks, "deltaBackoff");
            Guard.ArgumentNotGreaterThan(minBackoff.TotalMilliseconds, maxBackoff.TotalMilliseconds, "minBackoff must be less than or equal to maxBackoff");
            this.retryCount = retryCount;
            this.minBackoff = minBackoff;
            this.maxBackoff = maxBackoff;
            this.deltaBackoff = deltaBackoff;
        }
        public override ShouldRetry GetShouldRetry()
        {
            return (int currentRetryCount, Exception lastException, out TimeSpan retryInterval) =>
            {
                if (currentRetryCount < this.retryCount)
                {
                    var random = new Random();
                    double length = Math.Min(
                        this.minBackoff.TotalMilliseconds + (Math.Pow(2.0, currentRetryCount) - 1.0) * (0.8 + random.NextDouble() * 0.4) * this.deltaBackoff.TotalMilliseconds,
                        this.maxBackoff.TotalMilliseconds);
                    retryInterval = TimeSpan.FromMilliseconds(length);
                    return true;
                }
                else
                {
                    retryInterval = TimeSpan.Zero;
                    return false;
                }
            };
        }

    }

    public static class ShutdownHandler
    {
        /// <summary>
        /// Here are some references which were used for this code -
        /// https://stackoverflow.com/questions/40742192/how-to-do-gracefully-shutdown-on-dotnet-with-docker/43813871
        /// https://msdn.microsoft.com/en-us/library/system.gc.keepalive(v=vs.110).aspx
        /// </summary>
        public static (CancellationTokenSource cts, ManualResetEventSlim doneSignal, Option<object> handler)
            Init(TimeSpan shutdownWaitPeriod, ILogger logger)
        {
            var cts = new CancellationTokenSource();
            var completed = new ManualResetEventSlim();
            Option<object> handler = Option.None<object>();
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                WindowsShutdownHandler.HandlerRoutine hr = WindowsShutdownHandler.Init(cts, completed, shutdownWaitPeriod, logger);
                handler = Option.Some(hr as object);
            }
            else
            {
                LinuxShutdownHandler.Init(cts, completed, shutdownWaitPeriod, logger);
            }

            return (cts, completed, handler);
        }

        static class LinuxShutdownHandler
        {
            public static void Init(CancellationTokenSource cts, ManualResetEventSlim completed, TimeSpan shutdownWaitPeriod, ILogger logger)
            {
                void OnUnload(AssemblyLoadContext ctx) => CancelProgram();

                void CancelProgram()
                {
                    logger?.LogInformation("Termination requested, initiating shutdown.");
                    cts.Cancel();
                    logger?.LogInformation("Waiting for cleanup to finish");
                    // Wait for shutdown operations to complete.
                    if (completed.Wait(shutdownWaitPeriod))
                    {
                        logger?.LogInformation("Done with cleanup. Shutting down.");
                    }
                    else
                    {
                        logger?.LogInformation("Timed out waiting for cleanup to finish. Shutting down.");
                    }
                }

                AssemblyLoadContext.Default.Unloading += OnUnload;
                Console.CancelKeyPress += (sender, cpe) => CancelProgram();
                logger?.LogDebug("Waiting on shutdown handler to trigger");
            }
        }

        /// <summary>
        /// This is the recommended way to handle shutdown of windows containers. References -
        /// https://github.com/moby/moby/issues/25982
        /// https://gist.github.com/darstahl/fbb80c265dcfd1b327aabcc0f3554e56
        /// </summary>
        static class WindowsShutdownHandler
        {
            public delegate bool HandlerRoutine(CtrlTypes ctrlType);

            public enum CtrlTypes
            {
                CTRL_C_EVENT = 0,
                CTRL_BREAK_EVENT = 1,
                CTRL_CLOSE_EVENT = 2,
                CTRL_LOGOFF_EVENT = 5,
                CTRL_SHUTDOWN_EVENT = 6
            }

            public static HandlerRoutine Init(
                CancellationTokenSource cts,
                ManualResetEventSlim completed,
                TimeSpan waitPeriod,
                ILogger logger)
            {
                var hr = new HandlerRoutine(
                    type =>
                    {
                        logger?.LogInformation($"Received signal of type {type}");
                        if (type == CtrlTypes.CTRL_SHUTDOWN_EVENT)
                        {
                            logger?.LogInformation("Initiating shutdown");
                            cts.Cancel();
                            logger?.LogInformation("Waiting for cleanup to finish");
                            if (completed.Wait(waitPeriod))
                            {
                                logger?.LogInformation("Done with cleanup. Shutting down.");
                            }
                            else
                            {
                                logger?.LogInformation("Timed out waiting for cleanup to finish. Shutting down.");
                            }
                        }

                        return false;
                    });
                SetConsoleCtrlHandler(hr, true);
                logger?.LogDebug("Waiting on shutdown handler to trigger");
                return hr;
            }

            [DllImport("Kernel32")]
            static extern bool SetConsoleCtrlHandler(HandlerRoutine handler, bool add);
        }
    }
}
