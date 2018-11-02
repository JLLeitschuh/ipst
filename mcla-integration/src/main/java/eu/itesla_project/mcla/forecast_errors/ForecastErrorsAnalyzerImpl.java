/**
 * Copyright (c) 2016, All partners of the iTesla project (http://www.itesla-project.eu/consortium)
 * Copyright (c) 2016-2018, RTE (http://www.rte-france.com)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
package eu.itesla_project.mcla.forecast_errors;

import com.powsybl.computation.*;
import com.powsybl.iidm.network.Network;
import eu.itesla_project.mcla.NetworkUtils;
import eu.itesla_project.mcla.forecast_errors.data.ForecastErrorsHistoricalData;
import eu.itesla_project.modules.histo.HistoDbClient;
import eu.itesla_project.modules.mcla.ForecastErrorsAnalyzer;
import eu.itesla_project.modules.mcla.ForecastErrorsAnalyzerParameters;
import eu.itesla_project.modules.mcla.ForecastErrorsDataStorage;
import eu.itesla_project.modules.online.TimeHorizon;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

/*
   MCLA code 1.8.1
*/
/**
 *
 * @author Quinary <itesla@quinary.com>
 */
public class ForecastErrorsAnalyzerImpl implements ForecastErrorsAnalyzer {

    private static final Logger LOGGER = LoggerFactory.getLogger(ForecastErrorsAnalyzerImpl.class);

    private static final String WORKING_DIR_PREFIX = "itesla_forecasterrorsanalysis_";
    private static final String FEACSVFILENAME = "forecasterrors_historicaldata.csv";
    private static final String FEAINPUTFILENAME = "feanalyzerinput.mat";
    private static final String FEAOUTPUTFILENAME = "feanalyzeroutput.mat";
    private static final String FEASAMPLERFILENAME = "feasampleroutput.mat";

    private static final String M2PATHPREFIX = "feam2output_";
    private static final String MATPATHSUFFIX = ".mat";
    private static final String M1OUTPUTFILENAME = "feam1output.mat";
    private static final String M0OUTPUTFILENAME = "feam0output.mat";
    private static final String M0OUTPUTFILENAMECSV = M0OUTPUTFILENAME + ".csv";
    private static final String GUIOUTPUTFILENAME = "feaguioutput.mat";
    private static final String M2OUTPUTFILENAME = M2PATHPREFIX + CommandConstants.EXECUTION_NUMBER_PATTERN + MATPATHSUFFIX;

    private static final String FEA_M1 = "fea_m1";
    private static final String FEA_M2 = "fea_m2";
    private static final String FEA_M2_REDUCE = "fea_m2_reduce";
    private static final String FEA_M3_SAMPLING = "fea_m3_sampling";


    private final ComputationManager computationManager;
    private final ForecastErrorsDataStorage forecastErrorsDataStorage;
    private final HistoDbClient histoDbClient;

    private Network network;
    private ForecastErrorsAnalyzerConfig config = null;
    private ForecastErrorsAnalyzerParameters parameters;
    private ArrayList<String> generatorsIds = new ArrayList<String>();
    private ArrayList<String> loadsIds = new ArrayList<String>();

    public ForecastErrorsAnalyzerImpl(Network network, ComputationManager computationManager,
                                      ForecastErrorsDataStorage forecastErrorsDataStorage,
                                      HistoDbClient histoDbClient, ForecastErrorsAnalyzerConfig config) {
        this.network = Objects.requireNonNull(network, "network is null");
        this.computationManager = Objects.requireNonNull(computationManager, "computation manager is null");
        this.forecastErrorsDataStorage = Objects.requireNonNull(forecastErrorsDataStorage, "forecast errors data storage is null");
        this.histoDbClient = Objects.requireNonNull(histoDbClient, "HistoDb client is null");
        this.config = Objects.requireNonNull(config, "config is null");
        LOGGER.info(config.toString());
    }

    public ForecastErrorsAnalyzerImpl(Network network, ComputationManager computationManager,
                                      ForecastErrorsDataStorage forecastErrorsDataStorage, HistoDbClient histoDbClient) {
        this(network, computationManager, forecastErrorsDataStorage, histoDbClient, ForecastErrorsAnalyzerConfig.load());
    }

    @Override
    public String getName() {
        return "RSE Forecast Error Analyser";
    }

    @Override
    public String getVersion() {
        return null;
    }

    @Override
    public void init(ForecastErrorsAnalyzerParameters parameters) {
        Objects.requireNonNull(parameters, "forecast errors analizer parameters value is null");
        this.parameters = parameters;
        generatorsIds = parameters.isAllInjections() ? NetworkUtils.getGeneratorsIds(network) : NetworkUtils.getRenewableGeneratorsIds(network);
        loadsIds = NetworkUtils.getLoadsIds(network);
    }

    @Override
    public void run(TimeHorizon timeHorizon) throws Exception {

        if (forecastErrorsDataStorage.isForecastErrorsDataAvailable(parameters.getFeAnalysisId(), timeHorizon)) {
            throw new RuntimeException("Forecast errors data for " + parameters.getFeAnalysisId() + " analysis and " + timeHorizon.getName() + " time horizon already exists");
        }

        computationManager.execute(new ExecutionEnvironment(createEnv(), WORKING_DIR_PREFIX, config.isDebug()), new AbstractExecutionHandler<String>() {
            @Override
            public List<CommandExecution> before(Path workingDir) throws IOException {
                // get forecast errors historical data from histodb
                Path historicalDataCsvFile = workingDir.resolve(FEACSVFILENAME);
                try {
                    FEAHistoDBFacade.historicalDataToCsvFile(histoDbClient,
                            generatorsIds,
                            loadsIds,
                            parameters.getHistoInterval(),
                            historicalDataCsvFile);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }

                //Path historicalDataCsvFile = Paths.get("/itesla_data/MAT", "forecastsDiff_7nodes.csv");
                ForecastErrorsHistoricalData forecastErrorsHistoricalData = new HistoricalDataCreator(network, generatorsIds, loadsIds)
                        .createForecastErrorsHistoricalData(historicalDataCsvFile);
                Path historicalDataMatFile = Paths.get(workingDir.toString(), FEAINPUTFILENAME);
                new FEAMatFileWriter(historicalDataMatFile).writeHistoricalData(forecastErrorsHistoricalData);



                LOGGER.info("Running forecast errors analysis for {} network, {} time horizon", network.getId(), timeHorizon.getName());

                return Arrays.asList(new CommandExecution(createMatm1Cmd(historicalDataMatFile), 1, Integer.MAX_VALUE),
                        new CommandExecution(createMatm2Cmd(), parameters.getnClusters(), Integer.MAX_VALUE),
                        new CommandExecution(createMatm2reduceCmd(), 1, Integer.MAX_VALUE),
                        new CommandExecution(createMatm3Cmd(), 1, Integer.MAX_VALUE)
                        );
            }

            @Override
            public String after(Path workingDir, ExecutionReport report) throws IOException {
                report.log();
                if (report.getErrors().isEmpty()) {
                    // store forecast errors data, offline sampling, statistics and uncertainties data for the GUI
                    forecastErrorsDataStorage.storeForecastErrorsFiles(parameters.getFeAnalysisId(), timeHorizon, workingDir.resolve(FEAOUTPUTFILENAME), workingDir.resolve(FEASAMPLERFILENAME), workingDir.resolve(M0OUTPUTFILENAMECSV), workingDir.resolve(GUIOUTPUTFILENAME));
                    // store analysis parameters
                    forecastErrorsDataStorage.storeParameters(parameters.getFeAnalysisId(), timeHorizon, parameters);
                    return "OK";
                }
                return "KO";
            }
        }).join();

// v<=2.0.0 implementation
//        try (CommandExecutor executor = computationManager.newCommandExecutor(
//                createEnv(), WORKING_DIR_PREFIX, config.isDebug())) {
//
//            final Path workingDir = executor.getWorkingDir();
//
//            // get forecast errors historical data from histodb
//            Path historicalDataCsvFile = workingDir.resolve(FEACSVFILENAME);
//            FEAHistoDBFacade.historicalDataToCsvFile(histoDbClient,
//                                                     generatorsIds,
//                                                     loadsIds,
//                                                     parameters.getHistoInterval(),
//                                                     historicalDataCsvFile);
//
//            //Path historicalDataCsvFile = Paths.get("/itesla_data/MAT", "forecastsDiff_7nodes.csv");
//            ForecastErrorsHistoricalData forecastErrorsHistoricalData = new HistoricalDataCreator(network, generatorsIds, loadsIds)
//                    .createForecastErrorsHistoricalData(historicalDataCsvFile);
//            Path historicalDataMatFile = Paths.get(workingDir.toString(), FEAINPUTFILENAME);
//            new FEAMatFileWriter(historicalDataMatFile).writeHistoricalData(forecastErrorsHistoricalData);
//
//            LOGGER.info("Running forecast errors analysis for {} network, {} time horizon", network.getId(), timeHorizon.getName());
//            ExecutionReport report = executor.start(new CommandExecution(createMatm1Cmd(historicalDataMatFile), 1, Integer.MAX_VALUE));
//            report.log();
//            if (report.getErrors().isEmpty()) {
//                report = executor.start(new CommandExecution(createMatm2Cmd(), parameters.getnClusters(), Integer.MAX_VALUE));
//                report.log();
//                if (report.getErrors().isEmpty()) {
//                    report = executor.start(new CommandExecution(createMatm2reduceCmd(), 1, Integer.MAX_VALUE));
//                    report.log();
//                    if (report.getErrors().isEmpty()) {
//                        report = executor.start(new CommandExecution(createMatm3Cmd(), 1, Integer.MAX_VALUE));
//                        report.log();
//                    }
//                }
//            }
//
//            // store forecast errors data, offline sampling, statistics and uncertainties data for the GUI
//            forecastErrorsDataStorage.storeForecastErrorsFiles(parameters.getFeAnalysisId(), timeHorizon, workingDir.resolve(FEAOUTPUTFILENAME), workingDir.resolve(FEASAMPLERFILENAME), workingDir.resolve(M0OUTPUTFILENAMECSV), workingDir.resolve(GUIOUTPUTFILENAME));
//            // store analysis parameters
//            forecastErrorsDataStorage.storeParameters(parameters.getFeAnalysisId(), timeHorizon, parameters);
//        }
    }

    //function exitcode=FEA_MODULE1_HELPER(ifile, ofile,natS,ofile_forFPF,ofileGUI, IRs, Ks, s_flagPQ,s_method,tolvar,Nmin_obs_fract,Nmin_obs_interv,outliers,koutlier,imputation_meth,Ngaussians,percentile_historical,check_module0,toleranceS,iterationsS,epsiloS,conditional_samplingS,histo_estremeQs,thresGUIs,s_rng_seed)

    private Command createMatm1Cmd(Path historicalDataMatFile) {
        List<String> args1 = new ArrayList<>();
        args1.add(historicalDataMatFile.toAbsolutePath().toString());
        args1.add(M1OUTPUTFILENAME);
        args1.add(config.getNats());  //added in v1.8
        args1.add(M0OUTPUTFILENAME);
        args1.add(GUIOUTPUTFILENAME);
        args1.add("" + parameters.getIr());
        args1.add("" + parameters.getnClusters());
        args1.add("" + parameters.getFlagPQ());
        args1.add("" + parameters.getMethod());
        args1.add("" + config.getTolVar());
        args1.add("" + config.getnMinObsFract());
        args1.add("" + config.getNnz()); //added in v1.8.1
        args1.add("" + config.getnMinObsInterv());
        args1.add("" + parameters.getOutliers());
        args1.add("" + config.getkOutlier());
        args1.add("" + config.getImputationMeth());
        args1.add("" + config.getnGaussians());
        args1.add("" + parameters.getPercentileHistorical());
        // args1.add("" + parameters.getModalityGaussian()); removed in v1.8
        args1.add("" + config.getCheckModule0());
        args1.add("" + config.getTolerance());
        args1.add("" + config.getIterations());
        args1.add("" + config.getEpsilo());
        args1.add("" + parameters.getConditionalSampling());
        args1.add("" + config.getHisto_estremeQ()); //added in v1.8
        args1.add("" + config.getThresGUI()); //added in v1.8
        args1.add("" + config.getUnimod()); //added in v1.8.1
        args1.add("" + config.getModo_inv()); //added in v1.8.1
        args1.add("" + config.getIsdeterministic()); //added in v1.8.1
        args1.add("" + config.getIsuniform()); //added in v1.8.1
        args1.add("" + config.getOpt_GUI()); //added in v1.8.1
        args1.add("" + config.getOptFPF()); //added in v1.8.2
        args1.add("" + config.getHomothetic()); //added in v1.8.2
        args1.add("" + config.getModelConv()); //added in v1.8.3
        if (config.getRngSeed() != null) {
            args1.add(Integer.toString(config.getRngSeed()));
        }

        String feaM1;
        if (config.getBinariesDir() != null) {
            feaM1 = config.getBinariesDir().resolve(FEA_M1).toAbsolutePath().toString();
        } else {
            feaM1 = FEA_M1;
        }

        return new SimpleCommandBuilder()
                .id("fea_m1")
                .program(feaM1)
                .args(args1)
                .inputFiles(new InputFile(historicalDataMatFile.getFileName().toString()))
                .outputFiles(new OutputFile(M1OUTPUTFILENAME), new OutputFile(M0OUTPUTFILENAME), new OutputFile(M0OUTPUTFILENAMECSV), new OutputFile(GUIOUTPUTFILENAME))
                .build();
    }

    private Command createMatm2Cmd() {
        String feaM2;
        if (config.getBinariesDir() != null) {
            feaM2 = config.getBinariesDir().resolve(FEA_M2).toAbsolutePath().toString();
        } else {
            feaM2 = FEA_M2;
        }
        return new SimpleCommandBuilder()
                .id("fea_m2")
                .program(feaM2)
                .args(M1OUTPUTFILENAME,
                        M2OUTPUTFILENAME,
                        CommandConstants.EXECUTION_NUMBER_PATTERN,
                        // ""+parameters.getModalityGaussian(), removed in v1.8
                        "" + parameters.getIr(),
                        "" + config.gettFlags(),
                        "" + config.getIsdeterministic()) //added in v1.8.1
                .inputFiles(new InputFile(M1OUTPUTFILENAME))
                .outputFiles(new OutputFile(M2OUTPUTFILENAME))
                .build();
    }

    private Command createMatm2reduceCmd() {
        String feaM2Reduce;
        if (config.getBinariesDir() != null) {
            feaM2Reduce = config.getBinariesDir().resolve(FEA_M2_REDUCE).toAbsolutePath().toString();
        } else {
            feaM2Reduce = FEA_M2_REDUCE;
        }
        List<InputFile> m2partsfiles = new ArrayList<InputFile>(parameters.getnClusters() + 1);
        m2partsfiles.add(new InputFile(M1OUTPUTFILENAME));
        for (int i = 0; i < parameters.getnClusters(); i++) {
            m2partsfiles.add(new InputFile(M2PATHPREFIX + i + MATPATHSUFFIX));
        }
        return new SimpleCommandBuilder()
                .id("fea_m2_reduce")
                .program(feaM2Reduce)
                .args(M1OUTPUTFILENAME, ".",
                        M2PATHPREFIX,
                        "" + parameters.getnClusters(),
                        FEAOUTPUTFILENAME,
                        //  ""+parameters.getModalityGaussian(),  removed in v1.8
                        "" + config.getPercpuGaussLoad(),
                        "" + config.getPercpuGaussRes(),
                        "" + config.getCorrelationGauss(),
                        "" + config.getIsdeterministic(), //added in v1.8.1
                        "" + config.getPload_deterministic(), //added in v1.8.1
                        "" + config.getQload_deterministic(), //added in v1.8.1
                        "" + config.getBand_uniformPL(), //added in v1.8.1
                        "" + config.getBand_uniformQL(), //added in v1.8.1
                        "" + config.getBand_uniformPGEN(), //added in v1.8.1
                        "" + config.getCorrelation_fict_uniform()) //added in v1.8.1
                .inputFiles(m2partsfiles)
                .outputFiles(new OutputFile(FEAOUTPUTFILENAME))
                .build();
    }

    private Command createMatm3Cmd() {
        String feaM3;
        if (config.getBinariesDir() != null) {
            feaM3 = config.getBinariesDir().resolve(FEA_M3_SAMPLING).toAbsolutePath().toString();
        } else {
            feaM3 = FEA_M3_SAMPLING;
        }
        List<String> args1 = new ArrayList<>();
        args1.add(FEAOUTPUTFILENAME);
        args1.add(FEASAMPLERFILENAME);
        args1.add("" + parameters.getnSamples());
        args1.add("" + config.getIsdeterministic()); //added in v1.8.1
        if (config.getRngSeed() != null) {
            args1.add(Integer.toString(config.getRngSeed()));
        }

        return new SimpleCommandBuilder()
                .id(FEA_M3_SAMPLING)
                .program(feaM3)
                .args(args1)
                .inputFiles(new InputFile(FEAOUTPUTFILENAME))
                .outputFiles(new OutputFile(FEASAMPLERFILENAME))
                .build();

    }


    private Map<String, String> createEnv() {
        Map<String, String> env = new HashMap<>();
        env.put("MCRROOT", config.getRuntimeHomeDir().toString());
        env.put("LD_LIBRARY_PATH", config.getRuntimeHomeDir().resolve("runtime").resolve("glnxa64").toString()
                + ":" + config.getRuntimeHomeDir().resolve("bin").resolve("glnxa64").toString()
                + ":" + config.getRuntimeHomeDir().resolve("sys").resolve("os").resolve("glnxa64").toString());
        return env;
    }

}
