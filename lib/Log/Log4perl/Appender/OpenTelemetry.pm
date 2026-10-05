use v5.42;
package Log::Log4perl::Appender::OpenTelemetry;
# ABSTRACT: Send logs via OpenTelemetry

use OpenTelemetry qw( otel_logger_provider );
use OpenTelemetry::Constants qw(
    LOG_LEVEL_TRACE
    LOG_LEVEL_DEBUG
    LOG_LEVEL_INFO
    LOG_LEVEL_WARN
    LOG_LEVEL_ERROR
    LOG_LEVEL_FATAL
);
use Time::HiRes;

our @ISA = qw(Log::Log4perl::Appender);

=head1 SYNOPSIS

    use Log::Log4perl;
    use OpenTelemetry::SDK;

    my $log4perl_config = q{
        log4perl.logger = DEBUG, OpenTelemetry
        log4perl.appender.OpenTelemetry = Log::Log4perl::Appender::OpenTelemetry
        log4perl.appender.OpenTelemetry.layout = PatternLayout
        log4perl.appender.OpenTelemetry.layout.ConversionPattern = %m{chomp}
    };

    Log::Log4perl::init(\$log4perl_config);

    my $log = Log::Log4perl->get_logger();

    $log->warn('this is my message');

=head1 DESCRIPTION

This L<Log::Log4perl::Appender> gets a L<OpenTelemetry::Logs::LoggerProvider>, gets a logger via
L<OpenTelemetry::Logs::LoggerProvider/logger> and calls L<OpenTelemetry::Logs::Logger/emit_record>.

=cut

sub new ($proto, %args) {
    my $class = ref $proto || $proto;

    bless {
        %args,
    }, $class;
}

=method log

See L<Log::Log4perl::Appender/log>.

=cut

sub log ($self, %params) {
    state %LOG2OTEL = (
        TRACE => LOG_LEVEL_TRACE,
        DEBUG => LOG_LEVEL_DEBUG,
        INFO  => LOG_LEVEL_INFO,
        WARN  => LOG_LEVEL_WARN,
        ERROR => LOG_LEVEL_ERROR,
        FATAL => LOG_LEVEL_FATAL,
    );

    my $level = $params{log4p_level};

    my $severity_number = 0+$LOG2OTEL{$level};

    otel_logger_provider->logger->emit_record(
        timestamp       => Time::HiRes::time,
        severity_text   => $level,
        severity_number => $severity_number,
        scope_name      => $params{log4p_category},
        body            => $params{message},
    );

    return;
}
